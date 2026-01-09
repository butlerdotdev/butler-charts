# Butler Provider Harvester

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Butler infrastructure provider for Harvester HCI.

## Overview

This provider enables Butler to provision virtual machines on [Harvester HCI](https://harvesterhci.io/). It watches for MachineRequest CRs and creates/manages VMs in Harvester.

## Prerequisites

- Kubernetes 1.28+
- Helm 3.12+
- Butler CRDs installed
- Harvester cluster with:
  - Talos image uploaded (with qemu-guest-agent extension)
  - VM network configured

## Installation

```bash
helm install butler-provider-harvester oci://ghcr.io/butlerdotdev/charts/butler-provider-harvester \
  --namespace butler-system
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` | Number of controller replicas |
| image.repository | string | `ghcr.io/butlerdotdev/butler-provider-harvester` | Image repository |
| network.hostNetwork | bool | `true` | Use host network for Harvester API access |
| leaderElection.enabled | bool | `false` | Enable leader election |

## Harvester Setup

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
# Download ISO and upload to Harvester
```

### 2. Create ProviderConfig

```yaml
apiVersion: butler.butlerlabs.dev/v1alpha1
kind: ProviderConfig
metadata:
  name: harvester
  namespace: butler-system
spec:
  provider: harvester
  credentialsRef:
    name: harvester-kubeconfig
    namespace: butler-system
    key: kubeconfig
  harvester:
    namespace: default
    networkName: default/vm-network
    imageName: default/talos-v1.9.0
```

### 3. Create Credentials Secret

```bash
kubectl create secret generic harvester-kubeconfig \
  --from-file=kubeconfig=/path/to/harvester-kubeconfig \
  -n butler-system
```

## License

Apache License 2.0
