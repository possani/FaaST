#!/bin/bash

export DURATION=30m

# Remove images
docker run -it --entrypoint="" --network host minio/mc sh -c " \
    mc -q config host add local http://$CLOUD:31003 $LRZ_ACCESS_KEY $LRZ_SECRET_KEY; \
    mc -q rm --recursive --force local/openwhisk/ > /dev/null"

k6port=6565
for i in $(seq 1 $RANGE)
do
    payload="LOCAL_${FUNCTION^^}_PAYLOAD"
    if [ -z "${!payload}" ]
    then
        echo "There's no such variable ${payload}"
        continue
    fi
    export PAYLOAD=${!payload}

    # Copy images
    docker run -it --entrypoint="" --network host minio/mc sh -c " \
        mc -q config host add local http://$CLOUD:31003 $LRZ_ACCESS_KEY $LRZ_SECRET_KEY > /dev/null; \
        mc -q config host add remote http://$AWS:9000 $AWS_ACCESS_KEY $AWS_SECRET_KEY > /dev/null; \
        mc -q --json cp --recursive remote/openwhisk/ local/openwhisk/ " > minio-cp-$i-$DURATION.json

    # # List images
    # docker run -it --entrypoint="" --network host minio/mc sh -c " \
    #     mc -q config host add local http://$CLOUD:31003 $LRZ_ACCESS_KEY $LRZ_SECRET_KEY > /dev/null; \
    #     mc -q ls local/openwhisk/ "

    # Cloud
    export SERVER_IP=${CLOUD}
    k6 run --duration ${DURATION} \
            --out influxdb=http://admin:admin@${SERVER_IP}:31002/db \
            --summary-export=${FUNCTION}-local-${i}-summary-${DURATION}-cloud.json \
            --address localhost:$k6port ../script.js &
    ((k6port++))

    # Wait for the processes to finish
    sleep $DURATION
    while [ $(ps aux | grep k6 | wc -l) -gt 3 ]
    do
        echo "Waiting for the processes to finish..."
        sleep 10
    done

    sleep 5m

    # Clean up running PODs
    export KUBECONFIG=$PWD/../ansible/from_remote/cloud-master-01/etc/kubernetes/admin.conf
    kubectl -n openwhisk delete pod -l user-action-pod=true

    # Remove images
    docker run -it --entrypoint="" --network host minio/mc sh -c " \
        mc -q config host add local http://$CLOUD:31003 $LRZ_ACCESS_KEY $LRZ_SECRET_KEY > /dev/null; \
        mc -q rm --recursive --force local/openwhisk/ > /dev/null"

done

# for i in $(seq 1 $RANGE)
# do
#     # Fix json
#     tail -n 6 minio-cp-$i.json > minio-cp-$i.json
# done