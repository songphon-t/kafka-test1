# setup.sh - Build and deploy everything
#!/bin/bash

set -e

echo "=== Building Kafka Test Application ==="
docker build -t kafka-test-app:latest .

echo ""
echo "=== Creating Namespace ==="
kubectl apply -f kafka-k8s.yaml

echo ""
echo "=== Waiting for Kafka Brokers (KRaft mode) ==="
sleep 15
kubectl wait --for=condition=ready pod -l app=kafka -n kafka-lab --timeout=300s

echo ""
echo "=== Creating Kafka Topic ==="
kubectl run kafka-create-topic --rm -i --tty --restart=Never --image=confluentinc/cp-kafka:7.7.0 -n kafka-lab -- \
  kafka-topics --create --if-not-exists \
  --bootstrap-server kafka-0.kafka.kafka-lab.svc.cluster.local:9092 \
  --topic test-topic \
  --partitions 6 \
  --replication-factor 2

echo ""
echo "=== Deploying Producers and Consumers ==="
kubectl apply -f kafka-k8s.yaml

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Useful commands:"
echo "  - Scale producers:   kubectl scale deployment kafka-producer -n kafka-lab --replicas=5"
echo "  - Scale consumers:   kubectl scale deployment kafka-consumer -n kafka-lab --replicas=5"
echo "  - Scale Kafka:       kubectl scale statefulset kafka -n kafka-lab --replicas=5"
echo "  - View producer logs: kubectl logs -f -l app=kafka-producer -n kafka-lab"
echo "  - View consumer logs: kubectl logs -f -l app=kafka-consumer -n kafka-lab"
echo "  - Topic info:        kubectl run kafka-topics --rm -i --tty --restart=Never --image=confluentinc/cp-kafka:7.7.0 -n kafka-lab -- kafka-topics --describe --bootstrap-server kafka-0.kafka.kafka-lab.svc.cluster.local:9092 --topic test-topic"
echo "  - Consumer groups:   kubectl run kafka-groups --rm -i --tty --restart=Never --image=confluentinc/cp-kafka:7.7.0 -n kafka-lab -- kafka-consumer-groups --bootstrap-server kafka-0.kafka.kafka-lab.svc.cluster.local:9092 --describe --group test-consumer-group"
