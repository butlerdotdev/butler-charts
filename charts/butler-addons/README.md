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
  --version 0.3.0 \
  -n butler-system
```

## Configuration

### Addon Categories

| Category | Description | Default |
|----------|-------------|---------|
| `platform.enabled` | Core infrastructure addons (CNI, storage, ingress) | `true` |
| `optional.enabled` | Observability, security, and utility addons | `true` |

### Platform Addons

| Addon | Category | Description |
|-------|----------|-------------|
| cilium | cni | eBPF-based networking and security |
| metallb | loadbalancer | Bare metal load balancer |
| cert-manager | certmanager | Certificate management |
| longhorn | storage | Distributed block storage |
| traefik | ingress | Application proxy and ingress |
| metrics-server | observability | Resource metrics for HPA |

### Optional Addons

| Addon | Category | Description |
|-------|----------|-------------|
| prometheus-operator | observability | Full monitoring stack with Grafana |
| vector-agent | observability | Log/metric collection |
| vector-aggregator | observability | Log/metric aggregation |
| victoria-metrics | observability | Time series database |
| victoria-logs | observability | Log management |
| loki | observability | Log aggregation |
| tempo | observability | Distributed tracing |
| jaeger | observability | Distributed tracing |
| otel-collector | observability | OpenTelemetry collector |
| velero | backup | Backup and restore |
| flux | gitops | GitOps toolkit |
| argocd | gitops | GitOps continuous delivery |
| external-secrets | security | External secrets sync |
| sealed-secrets | security | GitOps-friendly secrets |
| external-dns | dns | DNS synchronization |
| istio | service-mesh | Traffic management |
| linkerd | service-mesh | Ultralight service mesh |
| cnpg | database | PostgreSQL operator |
| redis | database | In-memory cache |
| nats | messaging | High-performance messaging |
| rabbitmq | messaging | Message broker |

## Customization

### Disable specific addons

```yaml
# values.yaml
platform:
  enabled: true
  addons:
    metricsServer:
      enabled: false  # Disable Metrics Server

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
  addon: prometheus-operator
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
  labels:
    butler.butlerlabs.dev/source: builtin
    butler.butlerlabs.dev/category: observability
spec:
  displayName: Example Addon
  description: Description of what the addon provides
  category: observability  # cni|loadbalancer|storage|certmanager|ingress|observability|backup|gitops|security|dns|database|messaging|service-mesh|other
  icon: "📈"
  platform: false
  dependsOn:
    - cilium
  chart:
    repository: https://charts.example.com
    name: example
    defaultVersion: "1.0.0"
    availableVersions:
      - "1.0.0"
      - "0.9.0"
  defaults:
    namespace: example-system
    releaseName: example
    createNamespace: true
    timeout: "10m"
    values:
      key: value
  links:
    documentation: https://example.com/docs
    source: https://github.com/example/example
    homepage: https://example.com
```

## Upgrading

```bash
helm upgrade butler-addons oci://ghcr.io/butlerdotdev/charts/butler-addons \
  --version 0.3.0 \
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
