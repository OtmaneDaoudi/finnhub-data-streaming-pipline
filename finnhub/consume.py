import io
from kafka import KafkaConsumer
from avro.io import DatumReader, BinaryDecoder
import avro.schema

schema = avro.schema.parse(open("trade.avsc").read())
reader = DatumReader(schema)


def decode(msg_value):
    message_bytes = io.BytesIO(msg_value)
    decoder = BinaryDecoder(message_bytes)
    event_dict = reader.read(decoder)
    return event_dict


consumer = KafkaConsumer('market',
                         group_id=None,
                         auto_offset_reset = "earliest",
                         bootstrap_servers = "kafka-broker:9094",
                         value_deserializer = decode)
for msg in consumer:
    print(msg)
