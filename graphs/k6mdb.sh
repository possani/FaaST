#!/bin/bash

for storage in local lrz
do
    export KUBECONFIG=$PWD/../ansible/from_remote/local-master-01/etc/kubernetes/admin.conf
    export FUNCTION=mongodb

    for i in 1m 5m 15m 30m
    do
        export DURATION=$i
        
        payload="${FUNCTION^^}_${storage^^}_PAYLOAD"
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
            --summary-export=$(date +%s)-${FUNCTION}-${storage}-${DURATION}-single-summary.json

        sleep 5m

        # Clean up running PODs
        kubectl -n openwhisk delete pod -l user-action-pod=true

        sleep 5m
    done
done
