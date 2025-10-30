# Kafka K8s Lab

## Note
- this app for testing kafka cluster with simple producer and consumer apps
- security are not in concern here so best practice are not applied
- use with caustions
- lab create based on cluade output with some modifications

A complete Kubernetes lab environment for testing Apache Kafka 3.9 with scalable producers and consumers.

## Architecture

- **Kafka**: 3-broker cluster in KRaft mode (no Zookeeper!) - Kafka 3.9 via Confluent Platform 7.7.0
- **Producers**: 2 replicas (scalable) - Python app sending messages every 2 seconds
- **Consumers**: 2 replicas (scalable) - Python app in consumer group
- **PostgreSQL**: Optional database for testing data persistence
- **Topic**: `test-topic` with 6 partitions, replication factor 2

## Prerequisites

- Kubernetes cluster (minikube, kind, or similar)
- kubectl configured
- Docker installed

## Quick Start

1. **Create all files** in your working directory:
   - `producer.py`
   - `consumer.py`
   - `requirements.txt`
   - `Dockerfile`
   - `kafka-k8s.yaml`

2. **Run setup**:
```bash
chmod +x setup.sh
./setup.sh
```

3. **Watch the magic happen**:
```bash
# Watch producer logs
kubectl logs -f -l app=kafka-producer -n kafka-lab

# Watch consumer logs  
kubectl logs -f -l app=kafka-consumer -n kafka-lab
```

## Testing Scenarios

### Scale Consumers (Handle More Load)
```bash
# Scale to 5 consumers
kubectl scale deployment kafka-consumer -n kafka-lab --replicas=5

# Check consumer group distribution
kubectl run kafka-check --rm -i --tty --restart=Never \
  --image=confluentinc/cp-kafka:7.7.0 -n kafka-lab -- \
  kafka-consumer-groups --bootstrap-server kafka-0.kafka.kafka-lab.svc.cluster.local:9092 \
  --describe --group test-consumer-group
```

### Scale Producers (Increase Load)
```bash
# Scale to 10 producers
kubectl scale deployment kafka-producer -n kafka-lab --replicas=10

# Watch message rate increase
kubectl logs -f -l app=kafka-producer -n kafka-lab --tail=20
```

### Scale Kafka Cluster
```bash
# Scale from 3 to 5 brokers
kubectl scale statefulset kafka -n kafka-lab --replicas=5

# Wait for new brokers
kubectl wait --for=condition=ready pod kafka-3 kafka-4 -n kafka-lab --timeout=180s

# Verify cluster
kubectl exec -it kafka-0 -n kafka-lab -- kafka-broker-api-versions \
  --bootstrap-server localhost:9092
```

### Test Topic Rebalancing
```bash
# Describe topic to see partition distribution
kubectl exec -it kafka-0 -n kafka-lab -- kafka-topics \
  --describe --bootstrap-server localhost:9092 --topic test-topic

# Create partition reassignment (manual or use kafka-reassign-partitions)
```

### Monitor Consumer Lag
```bash
# Check lag continuously
watch kubectl run kafka-lag --rm -i --tty --restart=Never \
  --image=confluentinc/cp-kafka:7.7.0 -n kafka-lab -- \
  kafka-consumer-groups --bootstrap-server kafka-0.kafka.kafka-lab.svc.cluster.local:9092 \
  --describe --group test-consumer-group
```

## Useful Commands

### View Resources
```bash
kubectl get all -n kafka-lab
kubectl get pods -n kafka-lab -w
```

### Access Kafka CLI
```bash
kubectl exec -it kafka-0 -n kafka-lab -- bash
```

### List Topics
```bash
kubectl exec -it kafka-0 -n kafka-lab -- kafka-topics \
  --list --bootstrap-server localhost:9092
```

### Consume Messages Manually
```bash
kubectl exec -it kafka-0 -n kafka-lab -- kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --from-beginning
```

### Produce Messages Manually
```bash
kubectl exec -it kafka-0 -n kafka-lab -- kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic test-topic
```

### Check Kafka Performance
```bash
# Producer performance test
kubectl exec -it kafka-0 -n kafka-lab -- kafka-producer-perf-test \
  --topic test-topic \
  --num-records 10000 \
  --record-size 1000 \
  --throughput 1000 \
  --producer-props bootstrap.servers=localhost:9092

# Consumer performance test  
kubectl exec -it kafka-0 -n kafka-lab -- kafka-consumer-perf-test \
  --topic test-topic \
  --bootstrap-server localhost:9092 \
  --messages 10000
```

## Configuration Details

### Message Format
Producers send JSON messages:
```json
{
  "producer": "kafka-producer-xyz",
  "counter": 42,
  "timestamp": "2025-09-30T12:34:56.789",
  "message": "Test message 42 from kafka-producer-xyz"
}
```

### Consumer Group
- Group ID: `test-consumer-group`
- Auto-commit enabled
- Starting from earliest offset

### Resource Limits
Minimal config as requested:
- Kafka (KRaft): 512Mi-1Gi RAM, 250m-1000m CPU, 1Gi storage per broker
- Producer/Consumer: 64Mi-128Mi RAM, 50m-200m CPU
- PostgreSQL: 128Mi-256Mi RAM, 100m-500m CPU

## Testing with PostgreSQL

Connect consumer to PostgreSQL to persist messages:

```python
# Add to consumer.py
import psycopg2

conn = psycopg2.connect(
    host="postgres.kafka-lab.svc.cluster.local",
    database="kafkatest",
    user="testuser",
    password="testpass"
)
```

## Cleanup

```bash
./cleanup.sh
# or
kubectl delete namespace kafka-lab
```

## Troubleshooting

### Producers/Consumers not starting
```bash
# Check if Kafka is ready
kubectl get pods -n kafka-lab -l app=kafka

# Check logs
kubectl logs -l app=kafka -n kafka-lab --tail=50
```

### Topic creation failed
```bash
# Manually create topic
kubectl exec -it kafka-0 -n kafka-lab -- kafka-topics \
  --create --bootstrap-server localhost:9092 \
  --topic test-topic --partitions 6 --replication-factor 2
```

### Consumer lag building up
Scale up consumers or increase processing speed:
```bash
kubectl scale deployment kafka-consumer -n kafka-lab --replicas=10
```

## Advanced Testing Ideas

1. **Fault tolerance**: Delete a Kafka pod and watch rebalancing
2. **Network partitioning**: Use network policies to simulate splits
3. **Performance tuning**: Adjust batch sizes, linger.ms, compression
4. **Multi-topic**: Create multiple topics with different configs
5. **Transactions**: Add transactional producer/consumer code
6. **Schema Registry**: Add Confluent Schema Registry for Avro testing

## Notes

- Uses Kafka 3.9 in **KRaft mode** (Confluent Platform 7.7.0) - No Zookeeper!
- KRaft is the future of Kafka - simpler, more scalable, faster metadata operations
- Minimal resource allocation for local testing
- StatefulSets ensure stable network identities and persistent storage
- Each broker runs as both controller and broker (combined mode)
- Topic has 6 partitions to test consumer distribution
- Replication factor of 2 for fault tolerance testing
- Cluster ID is pre-set for consistent formatting