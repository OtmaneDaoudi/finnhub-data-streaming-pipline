FROM spark:3.5.1-scala2.12-java17-ubuntu

USER root

RUN set -ex; \
    apt-get update; \
    apt-get install -y python3 python3-pip; \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install pyyaml

WORKDIR /

COPY ./streaming/streaming.py ./finnhub/trade.avsc ./config.yaml ./

COPY ./streaming/streaming.sh ./streaming/submit_args.py ./

COPY ./streaming/testing.py ./

RUN chmod u+x /streaming.sh

RUN mkdir -p /tmp/checkpoint