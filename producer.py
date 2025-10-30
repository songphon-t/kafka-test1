# producer.py
import os
import time
import json
import socket
from datetime import datetime
from kafka import KafkaProducer
from kafka.errors import KafkaError

BOOTSTRAP_SERVERS = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092').split(',')
TOPIC = os.getenv('KAFKA_TOPIC', 'test-topic')
INTERVAL = int(os.getenv('PRODUCE_INTERVAL', '2'))
HOSTNAME = socket.gethostname()

producer = KafkaProducer(
    bootstrap_servers=BOOTSTRAP_SERVERS,
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    retries=5,
    max_in_flight_requests_per_connection=1
)

counter = 0
print(f"[{HOSTNAME}] Producer started. Sending to topic: {TOPIC}")

while True:
    try:
        message = {
            'producer': HOSTNAME,
            'counter': counter,
            'timestamp': datetime.utcnow().isoformat(),
            'message': f'Test message {counter} from {HOSTNAME}'
        }
        
        future = producer.send(TOPIC, value=message)
        record_metadata = future.get(timeout=10)
        
        print(f"[{HOSTNAME}] Sent msg {counter} to partition {record_metadata.partition} offset {record_metadata.offset}")
        counter += 1
        time.sleep(INTERVAL)
        
    except KafkaError as e:
        print(f"[{HOSTNAME}] Error: {e}")
        time.sleep(5)
    except KeyboardInterrupt:
        break

producer.close()
