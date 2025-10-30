# test-scaling.sh - Test scaling scenarios
#!/bin/bash

NAMESPACE="kafka-lab"

echo "=== Test 1: Scale up consumers to handle more load ==="
kubectl scale deployment kafka-consumer -n $NAMESPACE --replicas=5
kubectl wait --for=condition=ready pod -l app=kafka-consumer -n $NAMESPACE --timeout=60s
echo "Consumers scaled to 5. Watch logs with: kubectl logs -f -l app=kafka-consumer -n $NAMESPACE"
read -p "Press enter to continue..."

echo ""
echo "=== Test 2: Scale up producers to increase load ==="
kubectl scale deployment kafka-producer -n $NAMESPACE --replicas=5
kubectl wait --for=condition=ready pod -l app=kafka-producer -n $NAMESPACE --timeout=60s
echo "Producers scaled to 5. Watch logs with: kubectl logs -f -l app=kafka-producer -n $NAMESPACE"
read -p "Press enter to continue..."

echo ""
echo "=== Test 3: Check consumer group lag ==="
kubectl run kafka-check-lag --rm -i --tty --restart=Never --image=confluentinc/cp-kafka:7.7.0 -n $NAMESPACE -- \
  kafka-consumer-groups --bootstrap-server kafka-0.kafka.kafka-lab.svc.cluster.local:9092 \
  --describe --group test-consumer-group

echo ""
echo "=== Test 4: Scale Kafka cluster (add 2 more brokers) ==="
kubectl scale statefulset kafka -n $NAMESPACE --replicas=5
echo "Waiting for new Kafka brokers to be ready..."
kubectl wait --for=condition=ready pod kafka-3 -n $NAMESPACE --timeout=180s || true
kubectl wait --for=condition=ready pod kafka-4 -n $NAMESPACE --timeout=180s || true

echo ""
echo "=== Test 5: Verify Kafka cluster ==="
kubectl run kafka-cluster-info --rm -i --tty --restart=Never --image=confluentinc/cp-kafka:7.7.0 -n $NAMESPACE -- \
  kafka-broker-api-versions --bootstrap-server kafka-0.kafka.kafka-lab.svc.cluster.local:9092

echo ""
echo "=== Scaling tests complete! ==="