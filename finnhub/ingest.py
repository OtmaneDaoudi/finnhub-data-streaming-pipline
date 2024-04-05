import websocket
import json
import io
import avro
from avro.io import DatumWriter, BinaryEncoder
from kafka import KafkaProducer

PRODUCER = KafkaProducer(bootstrap_servers="localhost:9094")
TOPIC = "market"
SCHEMA = avro.schema.parse(open("trade.avsc").read())
WRITER = DatumWriter(SCHEMA)
BYTES_WRITER = io.BytesIO()
ENCODER = BinaryEncoder(BYTES_WRITER)


def on_message(ws, message):
    payload = json.loads(message)
    message = {
        "data": payload['data'],
        "type": payload['type'],
    }
    WRITER.write(message, ENCODER)
    raw_bytes = BYTES_WRITER.getvalue()
    PRODUCER.send(TOPIC, raw_bytes)


def on_error(ws, error):
    print(error)


def on_close(ws):
    print("### closed ###")


def on_open(ws):
    ws.send('{"type":"subscribe","symbol":"BINANCE:BTCUSDT"}')


if __name__ == "__main__":
    websocket.enableTrace(True)
    ws = websocket.WebSocketApp("wss://ws.finnhub.io?token=co7ap21r01qofja8vcl0co7ap21r01qofja8vclg",
                                on_message=on_message,
                                on_error=on_error,
                                on_close=on_close)
    ws.on_open = on_open
    ws.run_forever()
