# import json
# import io
# import avro
# from avro.io import DatumReader, BinaryDecoder
# from kafka import KafkaConsumer


# SCHEMA = avro.schema.parse(open("trade.avsc").read())
# consumer = KafkaConsumer('market',
#                          group_id=None,
#                          auto_offset_reset="earliest",
#                          bootstrap_servers="localhost:9094")
# for message in consumer:
#     print("hi")
#     print(message)

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
                         auto_offset_reset="earliest",
                         bootstrap_servers="localhost:9094",
                         value_deserializer = decode)
for msg in consumer:
    print(msg)
