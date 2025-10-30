# cleanup.sh - Remove everything
#!/bin/bash

echo "=== Deleting Kafka Lab Namespace ==="
kubectl delete namespace kafka-lab

echo ""
echo "=== Cleanup Complete! ==="
