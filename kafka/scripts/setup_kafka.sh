echo "Waiting for kafka to init"
kafka-topics.sh --bootstratp-server kafka-broker:9092 --topic market --create --partitions 1 --replication-factor 1
echo "Topic 'Market' created successfully"