#!/bin/bash

res=$(kafka-topics.sh --bootstrap-server localhost:9092 --list | grep market)

if [ -z $res ];then
    # topic already exists
    kafka-topics.sh --bootstrap-server kafka-broker:9092 --topic market --create --partitions 1 --replication-factor 1
fi