#!/bin/bash

export DURATION=30m

k6port=6565
for i in $(seq 1 $RANGE)
do
    for cluster in aws local
    do
        payload="${cluster^^}_${FUNCTION^^}_PAYLOAD"
        if [ -z "${!payload}" ]
        then
            echo "There's no such variable ${payload}"
            continue
        fi
        export PAYLOAD=${!payload}

        # Cloud
        export SERVER_IP=${CLOUD}
        k6 run --duration ${DURATION} \
               --out influxdb=http://admin:admin@${SERVER_IP}:31002/db \
               --summary-export=${FUNCTION}-${cluster}-${i}-summary-cloud.json \
               --address localhost:$k6port ../script.js &
        ((k6port++))

        # Edge
        export SERVER_IP=${EDGE}
        k6 run --duration ${DURATION} \
               --out influxdb=http://admin:admin@${SERVER_IP}:31002/db \
               --summary-export=${FUNCTION}-${cluster}-${i}-summary-edge.json \
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
        export KUBECONFIG=$PWD/../ansible/from_remote/edge-master-01/etc/kubernetes/admin.conf
        kubectl -n openwhisk delete pod -l user-action-pod=true

        sleep 5m
    done
done