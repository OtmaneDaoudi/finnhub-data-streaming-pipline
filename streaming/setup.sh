#!/bin/bash

curl -f http://localhost:8080/

if [ $? -ne 0 ];then
    exit 1
fi

. /env.sh

# --conf spark.driver.extraJavaOptions='-XX:+UseG1GC -XX:InitiatingHeapOccupancyPercent=35' --conf spark.sql.shuffle.partitions=${SHUFFLE_PARTITIONS}
spark-submit --master ${SPARK_MASTER} --driver-memory 1g --packages org.apache.spark:spark-sql-kafka-0-10_${SCALA_VERSION}:${SPARK_VERSION},org.apache.kafka:kafka-clients:${KAFKA_CLIENT_VERSION},org.apache.spark:spark-avro_${SCALA_VERSION}:${SPARK_VERSION},com.datastax.spark:spark-cassandra-connector-assembly_${SCALA_VERSION}:3.5.0,com.github.jnr:jnr-posix:3.1.19 --conf spark.cassandra.connection.host=${CASSANDRA_SERVER}:${CASSANDRA_PORT} /streaming.py &

exit 0