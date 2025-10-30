# consumer.py
import os
import json
import socket
from kafka import KafkaConsumer
from kafka.errors import KafkaError

BOOTSTRAP_SERVERS = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092').split(',')
TOPIC = os.getenv('KAFKA_TOPIC', 'test-topic')
GROUP_ID = os.getenv('KAFKA_GROUP_ID', 'test-consumer-group')
HOSTNAME = socket.gethostname()

consumer = KafkaConsumer(
    TOPIC,
    bootstrap_servers=BOOTSTRAP_SERVERS,
    group_id=GROUP_ID,
    auto_offset_reset='earliest',
    enable_auto_commit=True,
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

print(f"[{HOSTNAME}] Consumer started. Subscribed to: {TOPIC}, Group: {GROUP_ID}")

try:
    for message in consumer:
        data = message.value
        print(f"[{HOSTNAME}] Partition {message.partition} Offset {message.offset}: "
              f"From {data['producer']} - {data['message']}")
        
except KafkaError as e:
    print(f"[{HOSTNAME}] Error: {e}")
except KeyboardInterrupt:
    pass
finally:
    consumer.close()