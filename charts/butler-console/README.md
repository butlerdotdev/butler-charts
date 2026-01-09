# Butler Console

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Butler web-based management console for multi-cluster Kubernetes management.

## Overview

The Butler Console provides a web-based interface for managing:

- **Tenant Clusters** - Create, view, update, and delete tenant clusters
- **Teams** - Manage teams and their access to clusters
- **Addons** - Install and manage cluster addons
- **Monitoring** - View cluster health and metrics

The console consists of two components:
- **Server** - Go-based API backend
- **Frontend** - React-based web UI

## Prerequisites

- Kubernetes 1.28+
- Helm 3.12+
- Butler CRDs and controller installed

## Installation

### Basic Installation

```bash
helm install butler-console oci://ghcr.io/butlerdotdev/charts/butler-console \
  --namespace butler-system
```

### With Ingress

```bash
helm install butler-console oci://ghcr.io/butlerdotdev/charts/butler-console \
  --namespace butler-system \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=butler.example.com
```

### With TLS

```bash
helm install butler-console oci://ghcr.io/butlerdotdev/charts/butler-console \
  --namespace butler-system \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=butler.example.com \
  --set ingress.tls[0].secretName=butler-tls \
  --set ingress.tls[0].hosts[0]=butler.example.com
```

## Configuration

### Server Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server.enabled | bool | `true` | Enable server component |
| server.replicaCount | int | `1` | Number of server replicas |
| server.image.repository | string | `ghcr.io/butlerdotdev/butler-console-server` | Server image |
| server.resources.requests.cpu | string | `100m` | CPU request |
| server.resources.requests.memory | string | `128Mi` | Memory request |

### Frontend Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| frontend.enabled | bool | `true` | Enable frontend component |
| frontend.replicaCount | int | `1` | Number of frontend replicas |
| frontend.image.repository | string | `ghcr.io/butlerdotdev/butler-console-frontend` | Frontend image |
| frontend.resources.requests.cpu | string | `50m` | CPU request |
| frontend.resources.requests.memory | string | `64Mi` | Memory request |

### Ingress Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ingress.enabled | bool | `false` | Enable ingress |
| ingress.className | string | `""` | Ingress class name |
| ingress.hosts | list | `[]` | Ingress hosts |
| ingress.tls | list | `[]` | TLS configuration |

## High Availability

For production deployments:

```yaml
server:
  replicaCount: 2
  podDisruptionBudget:
    enabled: true
    minAvailable: 1

frontend:
  replicaCount: 2
  podDisruptionBudget:
    enabled: true
    minAvailable: 1
```

## Local Development

Access without ingress:

```bash
# Port forward frontend
kubectl port-forward -n butler-system svc/butler-console-frontend 3000:80

# Port forward server API
kubectl port-forward -n butler-system svc/butler-console-server 8080:8080

# Open browser
open http://localhost:3000
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Ingress                               │
└─────────────────────────────────────────────────────────────┘
                    │                         │
                    │ /api/*                  │ /*
                    ▼                         ▼
┌─────────────────────────────┐  ┌─────────────────────────────┐
│         Server              │  │        Frontend              │
│    (Go API Backend)         │  │    (React/Nginx)             │
│                             │  │                              │
│  • Kubernetes API           │  │  • Static assets             │
│  • Butler CRD operations    │  │  • SPA routing               │
│  • Authentication           │  │  • API proxy                 │
└─────────────────────────────┘  └─────────────────────────────┘
              │
              ▼
┌─────────────────────────────┐
│    Kubernetes API Server    │
│                             │
│  • TenantClusters          │
│  • Teams                    │
│  • TenantAddons            │
└─────────────────────────────┘
```

## License

Apache License 2.0
