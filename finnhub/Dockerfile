FROM python:3.8-alpine
WORKDIR /
COPY finnhub/trade.avsc finnhub/ingest.py finnhub/requirements.txt env.sh finnhub/setup.sh ./
RUN pip install -r requirements.txt
# RUN apt-get update && apt-get install source
CMD ["/setup.sh"]