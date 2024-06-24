FROM bitnami/spark:3.5.1

USER root

RUN apt update && apt install curl -y

WORKDIR /

COPY ./streaming/streaming.py ./finnhub/trade.avsc ./streaming/setup.sh env.sh ./

RUN chmod u+x /setup.sh