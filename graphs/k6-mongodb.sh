#!/bin/bash

export RUN=1
export SCRIPT=python-mongodb
export DURATION=60m


k6port=6565
for i in lrz local
do
    payload="${i^^}_MONGODB_PAYLOAD"
    export PAYLOAD=${!payload}
    export FILE_NAME=${i}-${RUN}

    # Cloud
    export SERVER_IP=${CLOUD}
    k6 run --duration ${DURATION} --out influxdb=http://admin:admin@${SERVER_IP}:31002/db --summary-export=${FILE_NAME}-summary-cloud-mongodb-"$(date +%s)".json --address localhost:$k6port ../script.js &
    ((k6port++))

    # Edge
    export SERVER_IP=${EDGE}
    k6 run --duration ${DURATION} --out influxdb=http://admin:admin@${SERVER_IP}:31002/db --summary-export=${FILE_NAME}-summary-edge-mongodb-"$(date +%s)".json --address localhost:$k6port ../script.js &
    ((k6port++))

    # Wait for the processes to finish
    k6_processes=$(ps aux | grep k6 | wc -l)
    while [ $k6_processes -gt 1 ]
    do
        sleep 60
        k6_processes=$(ps aux | grep k6 | wc -l)
    done

    # Clean up running PODs
    export KUBECONFIG=$PWD/../ansible/from_remote/cloud-master-01/etc/kubernetes/admin.conf
    kubectl -n openwhisk delete pod -l user-action-pod=true
    export KUBECONFIG=$PWD/../ansible/from_remote/edge-master-01/etc/kubernetes/admin.conf
    kubectl -n openwhisk delete pod -l user-action-pod=true
done