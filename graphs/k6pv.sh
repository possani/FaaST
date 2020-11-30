#!/bin/bash

for storage in local
do
    export KUBECONFIG=$PWD/../ansible/from_remote/local-master-01/etc/kubernetes/admin.conf
    export POD=$(kubectl -n openwhisk get pvc function-pvc --no-headers=true | cut -d' ' -f7)
    export FUNCTION=pv

    # Start with an empty PV
    ssh -i $HOME/.ssh/thesis-lrz ubuntu@$LOCAL rm -rf /mnt/share/$POD/*.png

    for case in single multiple
    do
        echo $case

        if [ $case == "single" ]
        then 
            scp -i $HOME/.ssh/thesis-lrz $PWD/images/sample000.png ubuntu@$LOCAL:/mnt/share/$POD/
        else
            scp -i $HOME/.ssh/thesis-lrz $PWD/images/sample00[0-9].png ubuntu@$LOCAL:/mnt/share/$POD/
        fi

        for i in 1m 5m 15m 30m
        do
            export DURATION=$i
            
                payload="${FUNCTION^^}_${storage^^}_${case^^}_PAYLOAD"
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
                    --summary-export=$(date +%s)-${FUNCTION}-${storage}-${DURATION}-${case}-summary.json

                sleep 5m

                # Clean up running PODs
                kubectl -n openwhisk delete pod -l user-action-pod=true

                sleep 5m
        done
    done

    # Empty PV
    ssh -i $HOME/.ssh/thesis-lrz ubuntu@$LOCAL rm -rf /mnt/share/$POD/*.png

done
