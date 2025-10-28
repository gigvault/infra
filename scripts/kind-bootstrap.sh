#!/bin/bash
# Bootstrap a kind cluster for GigVault

set -e

CLUSTER_NAME="gigvault"
CONFIG_FILE="$(dirname "$0")/../manifests/kind-config.yaml"

echo "==================================="
echo "GigVault Kind Cluster Bootstrap"
echo "==================================="

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ kind is not installed"
    echo "Install it from: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "⚠️  Cluster '$CLUSTER_NAME' already exists"
    read -p "Delete and recreate? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
        echo "Deleting existing cluster..."
        kind delete cluster --name "$CLUSTER_NAME"
    else
        echo "Using existing cluster"
        exit 0
    fi
fi

# Create kind cluster
echo "Creating kind cluster..."
kind create cluster \
  --name "$CLUSTER_NAME" \
  --config "$CONFIG_FILE"

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s

# Create namespace
echo "Creating gigvault namespace..."
kubectl create namespace gigvault || true

# Install PostgreSQL
echo "Installing PostgreSQL..."
kubectl apply -f "$(dirname "$0")/../manifests/postgresql.yaml"

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
kubectl wait --for=condition=Ready pod -l app=postgresql -n gigvault --timeout=120s

echo ""
echo "✅ Kind cluster '$CLUSTER_NAME' is ready!"
echo ""
echo "Next steps:"
echo "  1. Build services: make build-all"
echo "  2. Deploy: make deploy-local"
echo "  3. Test: make smoke-test"

