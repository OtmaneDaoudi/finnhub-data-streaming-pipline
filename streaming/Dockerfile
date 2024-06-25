FROM bitnami/spark:3.5.1

USER root

RUN apt update && apt install curl -y

WORKDIR /

COPY ./streaming/streaming.py ./finnhub/trade.avsc ./streaming/setup.sh env.sh ./

COPY ./streaming/spark-defaults.conf /opt/bitnami/spark/conf

RUN chmod u+x /setup.sh