#!/bin/bash

export SCRIPT=python-minio
export DURATION=60m
export FILE_NAME=aws

# Edge
export SERVER_IP=138.246.234.2
k6 run --duration ${DURATION} --out influxdb=http://admin:admin@${SERVER_IP}:31002/db --summary-export=${FILE_NAME}-summary-edge.json --address localhost:6565 ../script.js &

# Cloud
export SERVER_IP=138.246.234.239
k6 run --duration ${DURATION} --out influxdb=http://admin:admin@${SERVER_IP}:31002/db --summary-export=${FILE_NAME}-summary-cloud.json --address localhost:6566 ../script.js &
