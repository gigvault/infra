#!/bin/bash
# Deploy all services to local kind cluster

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHARTS_DIR="$(dirname "$SCRIPT_DIR")/charts"

echo "==================================="
echo "Deploying GigVault Services"
echo "==================================="

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed"
    exit 1
fi

SERVICES=(
  "ca:8080"
  "ra:8081"
  "keymgr:8082"
  "enroll:8083"
  "ocsp:8084"
  "crl:8085"
  "policy:8086"
  "auth:8087"
  "audit:8088"
  "notify:8089"
)

for svc_info in "${SERVICES[@]}"; do
  IFS=':' read -r svc port <<< "$svc_info"
  
  echo ""
  echo "Deploying $svc..."
  
  helm upgrade --install "$svc" "$CHARTS_DIR/$svc" \
    --namespace gigvault \
    --create-namespace \
    --set image.repository="gigvault/$svc" \
    --set image.tag="local" \
    --set image.pullPolicy="IfNotPresent" \
    --set service.port="$port" \
    --wait \
    --timeout 2m
  
  echo "✓ $svc deployed"
done

echo ""
echo "✅ All services deployed successfully!"
echo ""
echo "Access services:"
for svc_info in "${SERVICES[@]}"; do
  IFS=':' read -r svc port <<< "$svc_info"
  echo "  $svc: kubectl port-forward -n gigvault svc/$svc $port:$port"
done

