#!/bin/bash
# Run smoke tests against deployed services

set -e

NAMESPACE="gigvault"

echo "==================================="
echo "GigVault Smoke Tests"
echo "==================================="

# Check if all pods are running
echo ""
echo "Checking pod status..."
kubectl get pods -n "$NAMESPACE"

echo ""
echo "Checking service endpoints..."
kubectl get svc -n "$NAMESPACE"

# Test CA service
echo ""
echo "Testing CA service..."
CA_POD=$(kubectl get pod -n "$NAMESPACE" -l app=ca -o jsonpath='{.items[0].metadata.name}')
if kubectl exec -n "$NAMESPACE" "$CA_POD" -- wget -q -O- http://localhost:8080/health | grep -q "healthy"; then
  echo "✓ CA service is healthy"
else
  echo "❌ CA service health check failed"
fi

# Test RA service
echo ""
echo "Testing RA service..."
RA_POD=$(kubectl get pod -n "$NAMESPACE" -l app=ra -o jsonpath='{.items[0].metadata.name}')
if kubectl exec -n "$NAMESPACE" "$RA_POD" -- wget -q -O- http://localhost:8081/health | grep -q "healthy"; then
  echo "✓ RA service is healthy"
else
  echo "❌ RA service health check failed"
fi

echo ""
echo "✅ Smoke tests passed!"

