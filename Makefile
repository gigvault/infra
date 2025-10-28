.PHONY: kind-up kind-down build-all deploy-local smoke-test clean

# Create kind cluster
kind-up:
	@echo "Creating kind cluster..."
	./scripts/kind-bootstrap.sh

# Delete kind cluster
kind-down:
	kind delete cluster --name gigvault

# Build all Docker images
build-all:
	@echo "Building all services..."
	./scripts/build-all.sh

# Deploy all services to local cluster
deploy-local: build-all
	@echo "Initializing databases..."
	./scripts/init-databases.sh
	@echo "Deploying services..."
	./scripts/deploy-local.sh

# Run smoke tests
smoke-test:
	@echo "Running smoke tests..."
	./scripts/smoke-test.sh

# Clean up
clean:
	@echo "Cleaning up..."
	kind delete cluster --name gigvault || true
	docker rmi $$(docker images 'gigvault/*' -q) || true

