# Butler Addons

Helm chart containing Butler addon definitions - the catalog of available addons for tenant and management clusters.

## Overview

This chart installs `AddonDefinition` custom resources that define the available addons in Butler. These definitions are used by:

- **Butler Console** - displays available addons in the UI
- **Butler Controller** - references definitions when installing addons via `TenantAddon` or `ManagementAddon` resources

## Prerequisites

- Kubernetes 1.28+
- Helm 3.10+
- Butler CRDs installed (`butler-crds` chart)

## Installation

```bash
helm install butler-addons oci://ghcr.io/butlerdotdev/charts/butler-addons \
  --version 0.1.0 \
  -n butler-system
```

## Configuration

### Addon Categories

| Category | Description | Default |
|----------|-------------|---------|
| `platform.enabled` | Core infrastructure addons (CNI, storage, ingress) | `true` |
| `optional.enabled` | Observability, security, and utility addons | `true` |

### Platform Addons

| Addon | Type | Description |
|-------|------|-------------|
| cilium | CNI | eBPF-based networking and security |
| longhorn | Storage | Distributed block storage |
| metallb | LoadBalancer | Bare metal load balancer |
| cert-manager | Certificates | Certificate management |
| traefik | Ingress | Application proxy and ingress |
| flux | GitOps | GitOps toolkit |

### Optional Addons

| Addon | Category | Description |
|-------|----------|-------------|
| prometheus | Monitoring | Metrics and alerting |
| grafana | Monitoring | Visualization |
| victoria-metrics | Monitoring | Time series database |
| loki | Logging | Log aggregation |
| tempo | Tracing | Distributed tracing |
| jaeger | Tracing | Distributed tracing |
| velero | Backup | Backup and restore |
| external-dns | DNS | DNS synchronization |
| external-secrets | Secrets | External secrets sync |
| sealed-secrets | Secrets | GitOps-friendly secrets |
| istio | Service Mesh | Traffic management |
| linkerd | Service Mesh | Ultralight service mesh |
| cnpg | Database | PostgreSQL operator |
| redis | Database | In-memory cache |
| nats | Messaging | High-performance messaging |
| rabbitmq | Messaging | Message broker |

## Customization

### Disable specific addons

```yaml
# values.yaml
platform:
  enabled: true
  addons:
    flux:
      enabled: false  # Disable Flux

optional:
  enabled: true
  addons:
    istio:
      enabled: false  # Disable Istio
    linkerd:
      enabled: false  # Disable Linkerd
```

### Disable entire categories

```bash
helm install butler-addons oci://ghcr.io/butlerdotdev/charts/butler-addons \
  --set optional.enabled=false \
  -n butler-system
```

## Usage

After installation, view available addons:

```bash
kubectl get addondefinitions
```

Install an addon on a tenant cluster:

```yaml
apiVersion: butler.butlerlabs.dev/v1alpha1
kind: TenantAddon
metadata:
  name: prometheus
  namespace: butler-tenants
spec:
  clusterRef:
    name: my-cluster
  addon: prometheus
  values:
    prometheus:
      prometheusSpec:
        retention: 14d
```

## AddonDefinition Schema

Each addon definition includes:

```yaml
apiVersion: butler.butlerlabs.dev/v1alpha1
kind: AddonDefinition
metadata:
  name: example-addon
spec:
  name: example-addon
  displayName: Example Addon
  description: Description of the addon
  category: observability
  type: monitoring
  icon: https://example.com/icon.svg
  maintainer: Example Inc
  documentationURL: https://example.com/docs
  chart:
    repository: https://charts.example.com
    name: example
    version: "1.0.0"
    namespace: example-system
  defaultValues:
    key: value
  configurableValues:
    - path: replicaCount
      description: Number of replicas
      type: integer
      default: 1
  constraints:
    singleton: true
    scope: tenant  # tenant, management, or both
```

## Upgrading

```bash
helm upgrade butler-addons oci://ghcr.io/butlerdotdev/charts/butler-addons \
  --version 0.2.0 \
  -n butler-system
```

## Uninstalling

```bash
helm uninstall butler-addons -n butler-system
```

> **Note**: Uninstalling removes addon definitions but does not uninstall any addons already deployed to clusters.

## Contributing

To add a new addon definition:

1. Determine the category (platform or optional)
2. Add the `AddonDefinition` to the appropriate template file
3. Add configuration toggle in `values.yaml`
4. Update documentation
5. Submit a pull request

## License

Apache License 2.0 - see [LICENSE](../../LICENSE) for details.
