#!/bin/bash

# Start with an empty bucket
docker run -it --entrypoint="" --network host minio/mc sh -c " \
    mc -q config host add local http://$LOCAL:31003 $LOCAL_ACCESS_KEY $LOCAL_SECRET_KEY > /dev/null; \
    mc -q rm --recursive --force local/openwhisk/"

for case in single multiple partial
do
    if [ $case == "single" ]
    then 
        docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add local http://$LOCAL:31003 $LOCAL_ACCESS_KEY $LOCAL_SECRET_KEY > /dev/null;
            mc -q cp /tmp/images/sample00.png local/openwhisk/"
    elif [ $case == "multiple" ]
    then
        for i in {0..9}
        do
            docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
                mc -q config host add local http://$LOCAL:31003 $LOCAL_ACCESS_KEY $LOCAL_SECRET_KEY > /dev/null;
                mc find local/openwhisk --name \"sample$i.png\" mc -q cp /tmp/images/sample0$i.png local/openwhisk/"
        done
    else
        docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add local http://$LOCAL:31003 $LOCAL_ACCESS_KEY $LOCAL_SECRET_KEY > /dev/null;
            mc -q cp -r /tmp/images/ local/openwhisk/"
    fi

    for i in 5m 30m
    do
        export DURATION=$i
        for cluster in local remote
        do
            payload="${FUNCTION^^}_${cluster^^}_${case^^}_PAYLOAD"
            if [ -z "${!payload}" ]
            then
                echo "There's no such variable ${payload}"
                continue
            fi
            export PAYLOAD=${!payload}

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
done