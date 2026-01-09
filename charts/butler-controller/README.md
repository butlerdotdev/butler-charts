# Butler Controller

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Butler TenantCluster controller for Kubernetes-native multi-cluster management.

## Overview

The Butler Controller manages the lifecycle of TenantClusters, TenantAddons, and Teams. It works with Cluster API and infrastructure providers to provision and manage tenant Kubernetes clusters.

## Prerequisites

- Kubernetes 1.28+
- Helm 3.12+
- Butler CRDs installed (`butler-crds` chart)
- Cluster API installed (optional, for CAPI-based provisioning)

## Installation

### Install CRDs First

```bash
helm install butler-crds oci://ghcr.io/butlerdotdev/charts/butler-crds \
  --namespace butler-system \
  --create-namespace
```

### Install Controller

```bash
helm install butler-controller oci://ghcr.io/butlerdotdev/charts/butler-controller \
  --namespace butler-system
```

### With Edge Profile

```bash
helm install butler-controller oci://ghcr.io/butlerdotdev/charts/butler-controller \
  --namespace butler-system \
  -f https://raw.githubusercontent.com/butlerdotdev/butler-charts/main/profiles/edge.yaml
```

## Configuration

### Key Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` | Number of controller replicas |
| image.repository | string | `ghcr.io/butlerdotdev/butler-controller` | Image repository |
| image.tag | string | `""` | Image tag (defaults to appVersion) |
| leaderElection.enabled | bool | `true` | Enable leader election for HA |
| controller.logLevel | string | `info` | Log level (debug, info, warn, error) |
| resources.requests.cpu | string | `100m` | CPU request |
| resources.requests.memory | string | `128Mi` | Memory request |
| resources.limits.cpu | string | `500m` | CPU limit |
| resources.limits.memory | string | `256Mi` | Memory limit |
| metrics.enabled | bool | `true` | Enable Prometheus metrics |
| metrics.serviceMonitor.enabled | bool | `false` | Create ServiceMonitor |
| podDisruptionBudget.enabled | bool | `false` | Enable PDB |

### High Availability

For production deployments:

```yaml
replicaCount: 2

leaderElection:
  enabled: true

podDisruptionBudget:
  enabled: true
  minAvailable: 1

topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: butler-controller
```

### Prometheus Integration

Enable ServiceMonitor for Prometheus Operator:

```yaml
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
    scrapeTimeout: 10s
```

## Usage

### Create a TenantCluster

```yaml
apiVersion: butler.butlerlabs.dev/v1alpha1
kind: TenantCluster
metadata:
  name: production
  namespace: default
spec:
  name: production
  kubernetes:
    version: v1.30.0
  controlPlane:
    replicas: 3
  workers:
    pools:
      - name: general
        replicas: 3
        cpu: 4
        memoryMB: 8192
        diskGB: 100
  network:
    podCIDR: 10.244.0.0/16
    serviceCIDR: 10.96.0.0/12
```

### Check Status

```bash
kubectl get tenantclusters -A
kubectl describe tenantcluster production
```

## Troubleshooting

### Controller not starting

Check pod status:
```bash
kubectl get pods -n butler-system -l app.kubernetes.io/name=butler-controller
kubectl logs -n butler-system -l app.kubernetes.io/name=butler-controller
```

### CRDs not found

Ensure CRDs are installed:
```bash
kubectl get crd | grep butler
```

## License

Apache License 2.0
