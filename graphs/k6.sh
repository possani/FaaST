#!/bin/bash

for cluster in local remote
do
    CLUSTER=${cluster^^}
    CLUSTER_PORT=${cluster^^}_PORT
    CLUSTER_ACCESS_KEY=${cluster^^}_ACCESS_KEY
    CLUSTER_SECRET_KEY=${cluster^^}_SECRET_KEY

    echo $CLUSTER
    echo $CLUSTER_ACCESS_KEY
    echo $CLUSTER_SECRET_KEY
    echo $CLUSTER_PORT

    echo ${!CLUSTER}
    echo ${!CLUSTER_ACCESS_KEY}
    echo ${!CLUSTER_SECRET_KEY}
    echo ${!CLUSTER_PORT}
    
    # Start with an empty buckets
    docker run -it --entrypoint="" --network host minio/mc sh -c " \
        mc -q config host add cluster http://${!CLUSTER}:${!CLUSTER_PORT} ${!CLUSTER_ACCESS_KEY} ${!CLUSTER_SECRET_KEY} > /dev/null; \
        mc -q rm --recursive --force cluster/openwhisk/ ; \
        mc -q rm --recursive --force cluster/openwhisk2/ "

    for case in single multiple partial
    do
        echo $case

        if [ $case == "single" ]
        then 
            docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
                mc -q config host add local http://${!CLUSTER}:${!CLUSTER_PORT} ${!CLUSTER_ACCESS_KEY} ${!CLUSTER_SECRET_KEY} > /dev/null;
                mc -q cp /tmp/images/sample000.png local/openwhisk/"
        elif [ $case == "multiple" ]
        then
            for i in {0..9}
            do
                docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
                    mc -q config host add local http://${!CLUSTER}:${!CLUSTER_PORT} ${!CLUSTER_ACCESS_KEY} ${!CLUSTER_SECRET_KEY} > /dev/null;
                    mc -q cp /tmp/images/sample00$i.png local/openwhisk/"
            done
        else
            docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
                mc -q config host add local http://${!CLUSTER}:${!CLUSTER_PORT} ${!CLUSTER_ACCESS_KEY} ${!CLUSTER_SECRET_KEY} > /dev/null;
                mc -q cp -r /tmp/images/ local/openwhisk/"
        fi

        for i in 30m
        do
            export DURATION=$i
            
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
                export KUBECONFIG=$PWD/../ansible/from_remote/local-master-01/etc/kubernetes/admin.conf
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

