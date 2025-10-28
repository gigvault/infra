#!/bin/bash
# Initialize all required databases in PostgreSQL

set -e

echo "==================================="
echo "Initializing PostgreSQL Databases"
echo "==================================="

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgresql -n gigvault --timeout=120s

# Get PostgreSQL pod name
POSTGRES_POD=$(kubectl get pods -n gigvault -l app=postgresql -o jsonpath='{.items[0].metadata.name}')

echo "PostgreSQL pod: $POSTGRES_POD"

# Create databases
DATABASES=(
  "gigvault_ca"
  "gigvault_ra"
  "gigvault_keymgr"
  "gigvault_auth"
  "gigvault_audit"
  "gigvault_policy"
  "gigvault_enroll"
  "gigvault_ocsp"
  "gigvault_crl"
  "gigvault_notify"
)

for db in "${DATABASES[@]}"; do
  echo "Creating database: $db"
  kubectl exec -n gigvault "$POSTGRES_POD" -- psql -U gigvault -tc "SELECT 1 FROM pg_database WHERE datname = '$db'" | grep -q 1 || \
  kubectl exec -n gigvault "$POSTGRES_POD" -- psql -U gigvault -c "CREATE DATABASE $db;"
  echo "✓ $db ready"
done

echo ""
echo "✅ All databases initialized!"
echo ""

