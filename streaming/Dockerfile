FROM bitnami/spark:3.5.1

USER root

RUN pip3 install pyyaml

WORKDIR /

COPY ./streaming/streaming.py ./finnhub/trade.avsc ./config.yaml ./

COPY ./streaming/streaming.sh ./streaming/submit_args.py ./

RUN chmod u+x /streaming.sh