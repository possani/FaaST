#!/bin/bash

# Remove images
docker run -it --entrypoint="" --network host minio/mc sh -c " \
    mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null; \
    mc -q rm --recursive --force remote/openwhisk/"

for case in single multiple partial
do
    if [ $case == "single" ]
    then 
        docker run -v "$(pwd)"/images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null;
            mc -q cp /tmp/images/sample000.png remote/openwhisk/"
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

    for i in 30m
    do
        export DURATION=$i
        payload="${FUNCTION^^}_LOCAL_${case^^}_PAYLOAD"
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
            mc -q config host add local http://$LOCAL:31003 $LOCAL_ACCESS_KEY $LOCAL_SECRET_KEY > /dev/null; \
            mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null; \
            mc -q --json cp -r remote/openwhisk/ local/openwhisk/ " > ${DATE}-minio-local-cp-${DURATION}-${case}-migration.json

        export SERVER_IP=${LOCAL}
        DATE2=$(date +%s)
        DIFF=`expr $DATE2 - $DATE`
        k6 run ../script.js --duration ${DURATION} \
                --out influxdb=http://admin:admin@${SERVER_IP}:31002/db \
                --summary-export=${DATE}-${DIFF}-minio-local-cp-${DURATION}-${case}-summary.json     

        sleep 5m

        # Clean up running PODs
        export KUBECONFIG=$PWD/../ansible/from_remote/local-master-01/etc/kubernetes/admin.conf
        kubectl -n openwhisk delete pod -l user-action-pod=true

        sleep 5m
    done
done

# Remove images
docker run -it --entrypoint="" --network host minio/mc sh -c " \
    mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null; \
    mc -q rm --recursive --force remote/openwhisk/"
