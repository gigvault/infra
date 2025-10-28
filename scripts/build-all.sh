#!/bin/bash
# Build all GigVault service Docker images

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

SERVICES=(
  "ca"
  "ra"
  "keymgr"
  "enroll"
  "ocsp"
  "crl"
  "policy"
  "auth"
  "audit"
  "notify"
)

echo "==================================="
echo "Building GigVault Services"
echo "==================================="

for svc in "${SERVICES[@]}"; do
  echo ""
  echo "Building $svc..."
  
  # Build from root directory to access shared library
  cd "$ROOT_DIR"
  docker build -f "$svc/Dockerfile" -t "gigvault/$svc:local" .
  
  # Load into kind cluster
  kind load docker-image "gigvault/$svc:local" --name gigvault
  
  echo "✓ $svc built and loaded"
done

echo ""
echo "✅ All services built successfully!"

