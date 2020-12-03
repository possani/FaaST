#!/bin/bash

for cluster in lrz 
do
    export KUBECONFIG=$PWD/../ansible/from_remote/local-master-01/etc/kubernetes/admin.conf

    CLUSTER=${cluster^^}
    CLUSTER_PORT=${cluster^^}_PORT
    CLUSTER_ACCESS_KEY=${cluster^^}_ACCESS_KEY
    CLUSTER_SECRET_KEY=${cluster^^}_SECRET_KEY
    
    # Start with an empty buckets
    docker run -it --entrypoint="" --network host minio/mc sh -c " \
        mc -q config host add cluster http://${!CLUSTER}:${!CLUSTER_PORT} ${!CLUSTER_ACCESS_KEY} ${!CLUSTER_SECRET_KEY} > /dev/null; \
        mc -q rm --recursive --force cluster/openwhisk/ ; \
        mc -q rm --recursive --force cluster/openwhisk2/ "

    single_regex="000"  
    multiple_regex="00[0-9]"
    partial_regex="0[0-9][0-9]"
    partial1k_regex="*"

    for case in single multiple partial partial1k
    do
        echo $case
        regex=${case}_regex
        docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add local http://${!CLUSTER}:${!CLUSTER_PORT} ${!CLUSTER_ACCESS_KEY} ${!CLUSTER_SECRET_KEY} > /dev/null;
            mc -q find /tmp/images --regex \"sample${!regex}.png\" --exec \"mc -q cp {} local/openwhisk\" "        

        for i in 1m 5m 15m 30m
        do
            DURATION=$i
            payload="${FUNCTION^^}_${cluster^^}_${case^^}_PAYLOAD"
            if [ -z "${!payload}" ]
            then
                echo "There's no such variable ${payload}"
                continue
            fi
            export PAYLOAD=${!payload}
            echo $PAYLOAD

            export SERVER_IP=${LOCAL}
            k6 run ../script.js --duration ${DURATION} \
                --out influxdb=http://admin:admin@${SERVER_IP}:31002/db \
                --summary-export=$(date +%s)-${FUNCTION}-${cluster}-${DURATION}-${case}-summary.json

            sleep 5m

            # Clean up running PODs
            kubectl -n openwhisk delete pod -l user-action-pod=true

            sleep 5m
        done
    done

    # Empty bucket
    docker run -it --entrypoint="" --network host minio/mc sh -c " \
        mc -q config host add cluster http://${!CLUSTER}:${!CLUSTER_PORT} ${!CLUSTER_ACCESS_KEY} ${!CLUSTER_SECRET_KEY} > /dev/null; \
        mc -q rm --recursive --force cluster/openwhisk/ ; \
        mc -q rm --recursive --force cluster/openwhisk2/ "
done

