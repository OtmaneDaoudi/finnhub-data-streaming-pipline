from kafka import KafkaProducer
from avro.io import DatumWriter, BinaryEncoder
import websocket
import json
import io
import avro
import os

KAFKA_SERVER = os.environ["KAFKA_SERVER"]
KAFKA_PORT = os.environ["KAFKA_PORT"]
TOPIC = os.environ["TOPIC"]
TOKEN = os.environ["TOKEN"]


PRODUCER = KafkaProducer(bootstrap_servers=f"{KAFKA_SERVER}:{KAFKA_PORT}")
SCHEMA = avro.schema.parse(open("trade.avsc").read())


def on_message(ws, message):
    print("token : ", TOKEN)
    payload = json.loads(message)
    message = {
        "data": payload['data'],
        "type": payload['type'],
    }

    writer = DatumWriter(SCHEMA)
    bytes_writer = io.BytesIO()
    encoder = BinaryEncoder(bytes_writer)

    writer.write(message, encoder)
    raw_bytes = bytes_writer.getvalue()
    PRODUCER.send(TOPIC, raw_bytes)


def on_error(ws, error):
    print(error)


def on_close(ws):
    print("### closed ###")


def on_open(ws):
    ws.send('{"type":"subscribe","symbol":"BINANCE:BTCUSDT"}')


if __name__ == "__main__":
    websocket.enableTrace(True)
    ws = websocket.WebSocketApp(f"wss://ws.finnhub.io?token={TOKEN}",
                                on_message=on_message,
                                on_error=on_error,
                                on_close=on_close)
    ws.on_open = on_open
    ws.run_forever()
