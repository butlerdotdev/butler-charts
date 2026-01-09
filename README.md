# Butler Helm Charts

Official Helm charts for [Butler](https://github.com/butlerdotdev/butler) - a Kubernetes-native multi-cluster management platform.

## Overview

Butler is a Kubernetes-as-a-Service platform that enables organizations to deploy and manage Kubernetes clusters across multiple infrastructure providers (Harvester, Nutanix, Proxmox, and more) using a unified, GitOps-native approach.

## Charts

| Chart | Description | Version |
|-------|-------------|---------|
| [butler-crds](./charts/butler-crds) | Butler Custom Resource Definitions | 0.1.0 |
| [butler-bootstrap](./charts/butler-bootstrap) | Bootstrap controller for management cluster creation | 0.1.0 |
| [butler-controller](./charts/butler-controller) | TenantCluster lifecycle controller | 0.1.0 |
| [butler-provider-harvester](./charts/butler-provider-harvester) | Harvester HCI infrastructure provider | 0.1.0 |
| [butler-provider-nutanix](./charts/butler-provider-nutanix) | Nutanix AHV infrastructure provider | 0.1.0 |
| [butler-provider-proxmox](./charts/butler-provider-proxmox) | Proxmox VE infrastructure provider | 0.1.0 |
| [butler-console](./charts/butler-console) | Web-based management console | 0.1.0 |

## Installation

### Prerequisites

- Kubernetes 1.28+
- Helm 3.12+

### Add the Helm Repository

```bash
# OCI Registry (recommended)
helm pull oci://ghcr.io/butlerdotdev/charts/butler-crds --version 0.1.0

# Or use OCI directly
helm install butler-crds oci://ghcr.io/butlerdotdev/charts/butler-crds
```

### Install Butler CRDs (Required First)

```bash
helm install butler-crds oci://ghcr.io/butlerdotdev/charts/butler-crds \
  --namespace butler-system \
  --create-namespace
```

### Install Butler Controller

```bash
helm install butler-controller oci://ghcr.io/butlerdotdev/charts/butler-controller \
  --namespace butler-system
```

### Install Butler Console

```bash
helm install butler-console oci://ghcr.io/butlerdotdev/charts/butler-console \
  --namespace butler-system
```

## Deployment Profiles

Butler supports different deployment profiles for various environments:

### Core Profile (Default)

Full-featured deployment for production management clusters:

```bash
helm install butler-controller oci://ghcr.io/butlerdotdev/charts/butler-controller \
  --namespace butler-system \
  -f https://raw.githubusercontent.com/butlerdotdev/butler-charts/main/profiles/core.yaml
```

### Edge Profile

Resource-constrained deployment for edge locations, homelabs, and single-node clusters:

```bash
helm install butler-controller oci://ghcr.io/butlerdotdev/charts/butler-controller \
  --namespace butler-system \
  -f https://raw.githubusercontent.com/butlerdotdev/butler-charts/main/profiles/edge.yaml
```

## Air-Gap Installation

For air-gapped environments, download charts and images beforehand:

```bash
# Pull charts
helm pull oci://ghcr.io/butlerdotdev/charts/butler-crds --version 0.1.0
helm pull oci://ghcr.io/butlerdotdev/charts/butler-controller --version 0.1.0

# Install from local files
helm install butler-crds ./butler-crds-0.1.0.tgz --namespace butler-system
helm install butler-controller ./butler-controller-0.1.0.tgz --namespace butler-system
```

## Upgrading

### Upgrade CRDs

CRDs are managed separately to prevent accidental deletion:

```bash
helm upgrade butler-crds oci://ghcr.io/butlerdotdev/charts/butler-crds \
  --namespace butler-system
```

### Upgrade Controllers

```bash
helm upgrade butler-controller oci://ghcr.io/butlerdotdev/charts/butler-controller \
  --namespace butler-system
```

## Configuration

See individual chart READMEs for detailed configuration options:

- [butler-crds](./charts/butler-crds/README.md)
- [butler-bootstrap](./charts/butler-bootstrap/README.md)
- [butler-controller](./charts/butler-controller/README.md)
- [butler-provider-harvester](./charts/butler-provider-harvester/README.md)
- [butler-provider-nutanix](./charts/butler-provider-nutanix/README.md)
- [butler-provider-proxmox](./charts/butler-provider-proxmox/README.md)
- [butler-console](./charts/butler-console/README.md)

## Development

### Building Charts

```bash
# Package all charts
make package

# Package specific chart
helm package charts/butler-controller

# Lint all charts
make lint
```

### Publishing Charts

Charts are automatically published to GHCR on release via GitHub Actions.

```bash
# Manual push (requires authentication)
helm push butler-controller-0.1.0.tgz oci://ghcr.io/butlerdotdev/charts
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development guidelines.

## License

Apache License 2.0 - see [LICENSE](./LICENSE) for details.

## Links

- [Butler Documentation](https://docs.butlerlabs.dev)
- [Butler GitHub Organization](https://github.com/butlerdotdev)
- [Butler Labs](https://butlerlabs.dev)
