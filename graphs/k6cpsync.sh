#!/bin/bash

# Empty bucket
docker run -it --entrypoint="" --network host minio/mc sh -c " \
    mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null; \
    mc -q rm --recursive --force remote/openwhisk/"

docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null;
            mc -q cp -r /tmp/images/ remote/openwhisk/"

for case in single multiple partial
do
    if [ $case == "single" ]
    then 
        docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null;
            mc -q cp /tmp/images/sample00.png remote/openwhisk/"
    elif [ $case == "multiple" ]
    then
        for i in {0..9}
        do
            docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
                mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null;
                mc -q cp /tmp/images/sample0$i.png remote/openwhisk/"
        done
    else
        docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null;
            mc -q cp -r /tmp/images/ remote/openwhisk/"
    fi

    for i in 5m 30m
    do
        export DURATION=$i
        payload="${FUNCTION^^}_REMOTE_${case^^}_PAYLOAD"
        if [ -z "${!payload}" ]
        then
            echo "There's no such variable ${payload}"
            continue
        fi
        export PAYLOAD=${!payload}

        DATE=$(date +%s)
        # Copy images
        docker run -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add local http://$LOCAL:31003 $LOCAL_ACCESS_KEY $LOCAL_SECRET_KEY > /dev/null; \
            mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null; \
            mc -q --json cp -r remote/openwhisk/ local/openwhisk/ " | tee ${DATE}-minio-local-cp-parallel-${DURATION}-${case}-migration.json &

        export SERVER_IP=${LOCAL}
        SECONDS=0
        k6 run ../script.js --duration ${DURATION} \
                --out influxdb=http://admin:admin@${SERVER_IP}:31002/db \
                --summary-export=${DATE}-minio-local-cp-parallel-${i}-${case}-presummary.json &

        payload="${FUNCTION^^}_LOCAL_${case^^}_PAYLOAD"
        export PAYLOAD=${!payload}

        # Wait for the migration
        sleep 5
        while [ $(docker ps | wc -l) -gt 1 ]; do sleep 0.5; done

        pkill -x k6
        DURATION_SEC=$(( ${DURATION%"m"} * 60 ))
        REMAINING_TIME=$(( $DURATION_SEC - $SECONDS ))s
        echo $DURATION_SEC
        echo $SECONDS
        echo $REMAINING_TIME
        export DURATION=$REMAINING_TIME

        k6 run ../script.js --duration ${DURATION} \
                --out influxdb=http://admin:admin@${SERVER_IP}:31002/db \
                --summary-export=${DATE}-minio-local-cp-parallel-${i}-${case}-summary.json

        sleep 5m

        # Clean up running PODs
        export KUBECONFIG=$PWD/../ansible/from_remote/local-master-01/etc/kubernetes/admin.conf
        kubectl -n openwhisk delete pod -l user-action-pod=true

        # Remove images
        docker run -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add local http://$LOCAL:31003 $LOCAL_ACCESS_KEY $LOCAL_SECRET_KEY > /dev/null; \
            mc -q rm --recursive --force local/openwhisk/ > /dev/null"

        sleep 5m
    done
done
