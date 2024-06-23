import yaml

config = yaml.safe_load(open("/config.yaml", 'r').read())
config_kafka = config["kafka"]
config_spark = config["spark"]
config_cassandra = config["cassandra"]

TOPIC = config_kafka["TOPIC"]
KAFKA_SERVER = config_kafka["KAFKA_SERVER"]
KAFKA_PORT = config_kafka["KAFKA_PORT"]
KAFKA_CLIENT_VERSION = config_spark["KAFKA_CLIENT_VERSION"]

SCALA_VERSION = config_spark["SCALA_VERSION"]
SPARK_VERSION = config_spark["SPARK_VERSION"]
SPARK_MASTER = config_spark["SPARK_MASTER"]
SHUFFLE_PARTITIONS = config_spark["SHUFFLE_PARTITIONS"]

CASSANDRA_SERVER = config_cassandra["CASSANDRA_SERVER"]
CASSANDRA_PORT = config_cassandra["CASSANDRA_PORT"]

print(f"--master {SPARK_MASTER} "
      f"--packages org.apache.spark:spark-sql-kafka-0-10_{SCALA_VERSION}:{SPARK_VERSION},"
      f"org.apache.kafka:kafka-clients:{KAFKA_CLIENT_VERSION},"
      f"org.apache.spark:spark-avro_{SCALA_VERSION}:{SPARK_VERSION},"
      f"com.datastax.spark:spark-cassandra-connector-assembly_{SCALA_VERSION}:3.5.0,"
      f"com.github.jnr:jnr-posix:3.1.19 "
      f"--conf spark.cassandra.connection.host={CASSANDRA_SERVER}:{CASSANDRA_PORT} "
      f"--conf spark.standalone.submit.waitAppCompletion=true", end="")