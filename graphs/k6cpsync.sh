#!/bin/bash

for cluster in lrz 
do
    export KUBECONFIG=$PWD/../ansible/from_remote/local-master-01/etc/kubernetes/admin.conf
    
    CLUSTER=${cluster^^}
    CLUSTER_PORT=${cluster^^}_PORT
    CLUSTER_ACCESS_KEY=${cluster^^}_ACCESS_KEY
    CLUSTER_SECRET_KEY=${cluster^^}_SECRET_KEY

    single_regex="000"  
    multiple_regex="00[0-9]"
    partial_regex="0[0-9][0-9]"
    partial1k_regex="*"

    # Empty buckets
    docker run -it --entrypoint="" --network host minio/mc sh -c " \
        mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null; \
        mc -q config host add local http://${!CLUSTER}:${!CLUSTER_PORT} ${!CLUSTER_ACCESS_KEY} ${!CLUSTER_SECRET_KEY} > /dev/null; \
        mc -q rm --recursive --force remote/openwhisk/; \
        mc -q rm --recursive --force local/openwhisk/ "

    for case in single multiple partial partial1k
    do
        echo $case
        regex=${case}_regex
        docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null;
            mc -q find /tmp/images --regex \"sample${!regex}.png\" --exec \"mc -q cp {} remote/openwhisk\" "        

        for i in 1m 5m 15m 30m
        do
            export DURATION=$i
            payload="${FUNCTION^^}_REMOTE_${case^^}_PAYLOAD"
            if [ -z "${!payload}" ]
            then
                echo "There's no such variable ${payload}"
                continue
            fi

            export PAYLOAD=${!payload}
            echo $case
            echo $PAYLOAD

            DATE=$(date +%s)
            # Copy images
            docker run -it --entrypoint="" --network host minio/mc sh -c " \
                mc -q config host add local http://${!CLUSTER}:${!CLUSTER_PORT} ${!CLUSTER_ACCESS_KEY} ${!CLUSTER_SECRET_KEY} > /dev/null; \
                mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null; \
                mc -q --json cp -r remote/openwhisk/ local/openwhisk/ " | tee ${DATE}-minio-${cluster}-cp-parallel-${DURATION}-${case}-migration.json &

            export SERVER_IP=${LOCAL}
            SECONDS=0
            k6 run ../script.js --duration ${DURATION} \
                    --out influxdb=http://admin:admin@${SERVER_IP}:31002/db \
                    --summary-export=${DATE}-minio-${cluster}-cp-parallel-${i}-${case}-presummary.json &

            payload="${FUNCTION^^}_${CLUSTER}_${case^^}_PAYLOAD"
            export PAYLOAD=${!payload}
            echo $PAYLOAD
            
            # Wait for the migration
            sleep 5
            while [ $(docker ps | wc -l) -gt 1 ]; do sleep 0.5; done

            pkill -x k6
            DURATION_SEC=$(( ${DURATION%"m"} * 60 ))
            REMAINING_TIME=$(( $DURATION_SEC - $SECONDS ))s
            echo "duration in sec: $DURATION_SEC"
            echo "current time: $SECONDS"
            echo "remaining time: $REMAINING_TIME"
            export DURATION=$REMAINING_TIME

            k6 run ../script.js --duration ${DURATION} \
                    --out influxdb=http://admin:admin@${SERVER_IP}:31002/db \
                    --summary-export=${DATE}-minio-${cluster}-cp-parallel-${i}-${case}-summary.json

            sleep 5m

            # Clean up running PODs
            kubectl -n openwhisk delete pod -l user-action-pod=true

            # Remove images
            docker run -it --entrypoint="" --network host minio/mc sh -c " \
                mc -q config host add local http://${!CLUSTER}:${!CLUSTER_PORT} ${!CLUSTER_ACCESS_KEY} ${!CLUSTER_SECRET_KEY} > /dev/null; \
                mc -q rm --recursive --force local/openwhisk/ > /dev/null"

            sleep 5m
        done
    done

    # Empty buckets
    docker run -it --entrypoint="" --network host minio/mc sh -c " \
        mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null; \
        mc -q rm --recursive --force remote/openwhisk/"

done
