from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, window, col
from pyspark.sql.avro.functions import from_avro
from pyspark.sql.dataframe import DataFrame

import yaml

config = yaml.safe_load(open("/config.yaml", 'r').read())
config_kafka = config["kafka"]
config_spark = config["spark"]
config_cassandra = config["cassandra"]

TOPIC = config_kafka["TOPIC"]
KAFKA_SERVER = config_kafka["KAFKA_SERVER"]
KAFKA_PORT = config_kafka["KAFKA_PORT"]

APP_NAME = config_spark["APP_NAME"]

spark = SparkSession.builder\
   .appName(APP_NAME)\
   .getOrCreate()
print(spark)

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