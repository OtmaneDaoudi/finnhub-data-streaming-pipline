FROM python:3.8-alpine
WORKDIR /
COPY finnhub/trade.avsc finnhub/ingest.py finnhub/requirements.txt finnhub/consume.py  config.yaml ./
RUN pip install -r requirements.txt
CMD ["python", "ingest.py"]