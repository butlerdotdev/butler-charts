# Butler Bootstrap

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Butler Bootstrap controller for management cluster creation.

## Overview

The Butler Bootstrap controller handles the initial creation of management clusters. It processes ClusterBootstrap CRs to:

1. Create MachineRequest CRs for VM provisioning
2. Configure Talos Linux on provisioned VMs
3. Bootstrap the Kubernetes cluster
4. Install management cluster addons

**Note:** This controller is typically deployed automatically by `butleradm bootstrap` in a temporary KIND cluster. Direct installation is only needed for advanced use cases.

## Prerequisites

- Kubernetes 1.28+
- Helm 3.12+
- Butler CRDs installed
- A Butler infrastructure provider deployed

## Installation

```bash
helm install butler-bootstrap oci://ghcr.io/butlerdotdev/charts/butler-bootstrap \
  --namespace butler-system \
  --create-namespace
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` | Number of controller replicas |
| image.repository | string | `ghcr.io/butlerdotdev/butler-bootstrap` | Image repository |
| network.hostNetwork | bool | `true` | Use host network (required for infrastructure access) |
| leaderElection.enabled | bool | `false` | Enable leader election |
| caCerts.mountHostCerts | bool | `true` | Mount host CA certificates |

## How It Works

1. User creates a ClusterBootstrap CR
2. Controller creates MachineRequest CRs for each node
3. Infrastructure provider provisions VMs
4. Controller applies Talos config to VMs
5. Controller bootstraps Kubernetes cluster
6. Controller installs addons (Cilium, Longhorn, etc.)
7. Kubeconfig is stored in ClusterBootstrap status

## License

Apache License 2.0
