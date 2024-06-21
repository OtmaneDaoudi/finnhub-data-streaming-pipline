import websocket
import json
import io
import avro
import yaml
from avro.io import DatumWriter, BinaryEncoder
from kafka import KafkaProducer

config = yaml.safe_load(open("../config.yaml", 'r').read())
config_kafka = config["kafka"]
config_finnhub = config["finnhub"]

PRODUCER = KafkaProducer(bootstrap_servers=f"{config_kafka['KAFKA_SERVER']}:{config_kafka['KAFKA_PORT']}")
TOPIC = config_kafka["TOPIC"]
SCHEMA = avro.schema.parse(open("trade.avsc").read())


def on_message(ws, message):
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
    # ws.send('{"type":"subscribe","symbol":"COINBASE:BTC-USD"}')


if __name__ == "__main__":
    websocket.enableTrace(True)
    ws = websocket.WebSocketApp(f"wss://ws.finnhub.io?token={config_finnhub['TOKEN']}",
                                on_message=on_message,
                                on_error=on_error,
                                on_close=on_close)
    ws.on_open = on_open
    ws.run_forever()
