# GigVault Infrastructure

Infrastructure automation, Helm charts, and deployment scripts for GigVault PKI.

## Quick Start

```bash
# Create local kind cluster
make kind-up

# Build all service images
make build-all

# Deploy all services
make deploy-local

# Run smoke tests
make smoke-test
```

## Repository Structure

```
infra/
├── charts/              # Helm charts for all services
│   ├── ca/
│   ├── ra/
│   ├── keymgr/
│   └── ...
├── scripts/            # Deployment and utility scripts
│   ├── kind-bootstrap.sh
│   ├── build-all.sh
│   ├── deploy-local.sh
│   └── smoke-test.sh
├── manifests/          # Kubernetes manifests
│   ├── kind-config.yaml
│   ├── postgresql.yaml
│   └── secrets.yaml (example)
└── Makefile           # Main orchestration
```

## Available Commands

| Command | Description |
|---------|-------------|
| `make kind-up` | Create kind cluster |
| `make kind-down` | Delete kind cluster |
| `make build-all` | Build all Docker images |
| `make deploy-local` | Deploy all services |
| `make smoke-test` | Run health checks |
| `make clean` | Remove cluster and images |

## Documentation

- [Local Bootstrap Guide](../docs/guides/BOOTSTRAP_LOCAL.md)
- [Production Deployment](../docs/guides/DEPLOYMENT.md)
- [Architecture](../docs/architecture/ARCHITECTURE.md)

## License

Copyright © 2025 GigVault

