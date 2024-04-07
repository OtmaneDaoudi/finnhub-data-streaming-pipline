FROM python:3.8-alpine
WORKDIR /
COPY ingest.py requirements.txt consume.py trade.avsc ./
RUN pip install -r requirements.txt
CMD ["python", "ingest.py"]