from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, window, col
from pyspark.sql.avro.functions import from_avro
from pyspark.sql.dataframe import DataFrame

from time import sleep

TOPIC = "market"
KAFKA_SERVER = "kafka-broker"
KAFKA_PORT = 9094
KAFKA_CLIENT_VERSION = "3.7.0"

SCALA_VERSION = '2.12'
SPARK_VERSION = '3.5.1'
SPARK_MASTER = "spark://spark-master:7077"
SHUFFLE_PARTITIONS = 20

CASSANDRA_SERVER = "cassandra"
CASSANDRA_PORT = 9042

APP_NAME = "BigDataStreaming"

packages = [
    f'org.apache.spark:spark-sql-kafka-0-10_{SCALA_VERSION}:{SPARK_VERSION}',
    f'org.apache.kafka:kafka-clients:{KAFKA_CLIENT_VERSION}',
    f'org.apache.spark:spark-avro_{SCALA_VERSION}:{SPARK_VERSION}',
    f"com.datastax.spark:spark-cassandra-connector-assembly_{SCALA_VERSION}:3.5.0"
]

spark = SparkSession.builder\
   .master(SPARK_MASTER)\
   .appName(APP_NAME)\
   .config("spark.sql.shuffle.partitions", f'{SHUFFLE_PARTITIONS}')\
   .config("spark.jars.packages", ",".join(packages))\
   .config("spark.cassandra.connection.host",f"{CASSANDRA_SERVER}:{CASSANDRA_PORT}")\
   .getOrCreate()
spark

market_stream: DataFrame = spark.readStream.format("kafka")\
    .option("kafka.bootstrap.servers", f"{KAFKA_SERVER}:{KAFKA_PORT}")\
    .option("subscribe", "market")\
    .option("startingOffsets", "earliest")\
    .option("failOnDataLoss", "false")\
    .load()
market_stream.printSchema()
avro_schema = open("/trade.avsc", "r").read()

trades_stream = market_stream\
    .withColumn("trade_data", from_avro("value", avro_schema))\
    .select("trade_data.*", "offset")\
    .select(explode("data"), "type", "offset")\
    .select("col.*", "offset")\
    .selectExpr("p as price", "s as symbol", "v as volume", "t as event_time", "offset")\
    .withColumn("event_time",(col("event_time") / 1000).cast("timestamp"))

trades_stream.printSchema()

trades_stream.writeStream\
    .queryName("trades")\
    .format("org.apache.spark.sql.cassandra") \
    .option("checkpointLocation", '/tmp/checkpoint/trades/') \
    .options(table = "trades", keyspace = "market") \
    .outputMode("append")\
    .start()

minute_trades_query = trades_stream\
    .withWatermark("event_time", "1 seconds")\
    .groupby("symbol", window("event_time", "1 minute"))\
    .agg({"*" : "count", "price" : "avg", "offset" : "max"})\
    .withColumnsRenamed({"avg(price)":"avg_price", "count(1)":"total"})\
    .selectExpr("symbol", "window.end as event_time", "avg_price", "total")

minute_trades_query.printSchema()
    
minute_trades_query.writeStream\
    .format("org.apache.spark.sql.cassandra") \
    .option("checkpointLocation", '/tmp/checkpoint/minute_trades/') \
    .options(table = "minute_trades", keyspace = "market") \
    .outputMode("Append")\
    .start()