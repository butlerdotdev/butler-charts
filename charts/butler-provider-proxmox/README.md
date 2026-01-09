# Butler Provider Proxmox

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Butler infrastructure provider for Proxmox VE.

## Overview

This provider enables Butler to provision virtual machines on [Proxmox VE](https://proxmoxhci.io/). It watches for MachineRequest CRs and creates/manages VMs in Proxmox.

## Prerequisites

- Kubernetes 1.28+
- Helm 3.12+
- Butler CRDs installed
- Proxmox cluster with:
  - Talos image uploaded (with qemu-guest-agent extension)
  - VM network configured

## Installation

```bash
helm install butler-provider-proxmox oci://ghcr.io/butlerdotdev/charts/butler-provider-proxmox \
  --namespace butler-system
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` | Number of controller replicas |
| image.repository | string | `ghcr.io/butlerdotdev/butler-provider-proxmox` | Image repository |
| network.hostNetwork | bool | `true` | Use host network for Proxmox API access |
| leaderElection.enabled | bool | `false` | Enable leader election |

## Proxmox Setup

### 1. Upload Talos Image

Download the Talos image with qemu-guest-agent:

```bash
# Generate schematic with qemu-guest-agent
curl -X POST --data-binary @- https://factory.talos.dev/schematics <<EOF
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/qemu-guest-agent
EOF
# Download ISO and upload to Proxmox
```

### 2. Create ProviderConfig

```yaml
apiVersion: butler.butlerlabs.dev/v1alpha1
kind: ProviderConfig
metadata:
  name: proxmox
  namespace: butler-system
spec:
  provider: proxmox
  credentialsRef:
    name: proxmox-kubeconfig
    namespace: butler-system
    key: kubeconfig
  proxmox:
    namespace: default
    networkName: default/vm-network
    imageName: default/talos-v1.9.0
```

### 3. Create Credentials Secret

```bash
kubectl create secret generic proxmox-kubeconfig \
  --from-file=kubeconfig=/path/to/proxmox-kubeconfig \
  -n butler-system
```

## License

Apache License 2.0
