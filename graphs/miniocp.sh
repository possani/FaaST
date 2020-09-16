#!/bin/bash

regex=("00" "0[0-4]" "0[0-9]" "[0-4][0-9]" "[0-9][0-9]")
for i in {1..5}
do
    # Empty buckets
    docker run -it --entrypoint="" --network host minio/mc sh -c " \
        mc -q config host add local http://$LOCAL:31003 $LOCAL_ACCESS_KEY $LOCAL_SECRET_KEY > /dev/null; \
        mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null; \
        mc -q rm --recursive --force local/test/; \
        mc -q rm --recursive --force remote/test/ "

    n_of_images=1
    mult=1    
    for j in ${!regex[@]}
    do
        r=${regex[$j]}
        n_of_images=$(( $n_of_images * $mult ))

        echo $r

        # Populate remote bucket
        docker run -v "$(pwd)"/large_images:/tmp/images -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null;
            mc -q find /tmp/images --name \"sample$r.png\" --exec \"mc -q cp {} remote/test\" "

        # Copy data from remote to local
        docker run -it --entrypoint="" --network host minio/mc sh -c " \
            mc -q config host add local http://$LOCAL:31003 $LOCAL_ACCESS_KEY $LOCAL_SECRET_KEY > /dev/null; \
            mc -q config host add remote http://$REMOTE:9000 $REMOTE_ACCESS_KEY $REMOTE_SECRET_KEY > /dev/null; \
            mc -q --json cp -r remote/test/ local/test/ " > run-$i-minio-cp-large-$n_of_images-from-remote.json

        if [ $(($j%2)) -eq 0 ]
        then
            mult=5
        else
            mult=2
        fi
    done
done
