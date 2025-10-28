#!/bin/bash
# Generate Kubernetes secrets securely

set -e

NAMESPACE="gigvault"

echo "🔐 Generating Kubernetes Secrets for GigVault..."
echo ""

# Create namespace if not exists
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 1. Generate PostgreSQL password
echo "📦 1/6 Generating PostgreSQL secret..."
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
kubectl create secret generic postgresql-secret \
  --from-literal=POSTGRES_USER=gigvault \
  --from-literal=POSTGRES_PASSWORD="$DB_PASSWORD" \
  --from-literal=POSTGRES_DB=gigvault \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ PostgreSQL secret created"

# 2. Generate JWT keys (ECDSA P-256)
echo ""
echo "🔑 2/6 Generating JWT signing keys..."
JWT_DIR=$(mktemp -d)
openssl ecparam -genkey -name prime256v1 -noout -out "$JWT_DIR/private.pem"
openssl ec -in "$JWT_DIR/private.pem" -pubout -out "$JWT_DIR/public.pem"

kubectl create secret generic jwt-keys \
  --from-file=private.pem="$JWT_DIR/private.pem" \
  --from-file=public.pem="$JWT_DIR/public.pem" \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

rm -rf "$JWT_DIR"
echo "✅ JWT keys created"

# 3. Generate CA private key (for development - use HSM in production!)
echo ""
echo "🏛️  3/6 Generating CA private key..."
CA_DIR=$(mktemp -d)
openssl ecparam -genkey -name prime256v1 -noout -out "$CA_DIR/ca-key.pem"

kubectl create secret generic ca-key \
  --from-file=key.pem="$CA_DIR/ca-key.pem" \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

rm -rf "$CA_DIR"
echo "✅ CA key created"

# 4. Generate TLS certificates (self-signed for development)
echo ""
echo "🔒 4/6 Generating TLS certificates..."
TLS_DIR=$(mktemp -d)
openssl req -x509 -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout "$TLS_DIR/tls.key" -out "$TLS_DIR/tls.crt" \
  -days 365 -nodes \
  -subj "/CN=gigvault.local/O=GigVault/C=US"

kubectl create secret tls tls-certs \
  --cert="$TLS_DIR/tls.crt" \
  --key="$TLS_DIR/tls.key" \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

rm -rf "$TLS_DIR"
echo "✅ TLS certificates created"

# 5. Generate database client certificates
echo ""
echo "💾 5/6 Generating database client certificates..."
DB_CERTS_DIR=$(mktemp -d)

# CA for database
openssl req -x509 -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout "$DB_CERTS_DIR/ca-key.pem" -out "$DB_CERTS_DIR/ca.crt" \
  -days 365 -nodes \
  -subj "/CN=PostgreSQL CA/O=GigVault/C=US"

# Client certificate
openssl ecparam -genkey -name prime256v1 -noout -out "$DB_CERTS_DIR/client.key"
openssl req -new -key "$DB_CERTS_DIR/client.key" -out "$DB_CERTS_DIR/client.csr" \
  -subj "/CN=gigvault/O=GigVault/C=US"
openssl x509 -req -in "$DB_CERTS_DIR/client.csr" \
  -CA "$DB_CERTS_DIR/ca.crt" -CAkey "$DB_CERTS_DIR/ca-key.pem" \
  -CAcreateserial -out "$DB_CERTS_DIR/client.crt" -days 365

kubectl create secret generic db-client-certs \
  --from-file=client.crt="$DB_CERTS_DIR/client.crt" \
  --from-file=client.key="$DB_CERTS_DIR/client.key" \
  --from-file=ca.crt="$DB_CERTS_DIR/ca.crt" \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

rm -rf "$DB_CERTS_DIR"
echo "✅ Database client certificates created"

# 6. Generate encryption key
echo ""
echo "🔐 6/6 Generating encryption key..."
ENCRYPTION_KEY=$(openssl rand -base64 32)
kubectl create secret generic encryption-key \
  --from-literal=ENCRYPTION_KEY="$ENCRYPTION_KEY" \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Encryption key created"

echo ""
echo "🎉 All secrets generated successfully!"
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "1. These are self-signed certificates for DEVELOPMENT only"
echo "2. In PRODUCTION, use:"
echo "   - Real CA-signed certificates"
echo "   - HSM or cloud KMS for CA keys"
echo "   - Sealed Secrets or External Secrets Operator"
echo "   - HashiCorp Vault for secret management"
echo "3. NEVER commit secrets to git!"
echo "4. Rotate secrets regularly (90 days recommended)"
echo ""
echo "📋 Secrets created in namespace: $NAMESPACE"
kubectl get secrets -n $NAMESPACE

