#!/bin/bash

source ./env.sh

res=$(kafka-topics.sh --bootstrap-server ${KAFKA_SERVER}:${KAFKA_PORT} --list | grep ${TOPIC})

if [ -z $res ];then
    # topic already exists
    kafka-topics.sh --bootstrap-server ${KAFKA_SERVER}:${KAFKA_PORT} --topic ${TOPIC} --create --partitions 1 --replication-factor 1
fi