# Butler CRDs

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: v1alpha1](https://img.shields.io/badge/AppVersion-v1alpha1-informational?style=flat-square)

Butler Custom Resource Definitions for Kubernetes-native multi-cluster management.

## Overview

This chart installs the Custom Resource Definitions (CRDs) required by Butler. CRDs are installed separately from controllers to:

- Enable independent CRD upgrades without controller restarts
- Prevent accidental CRD deletion when uninstalling controllers
- Follow CNCF best practices (cert-manager, Flux, etc.)

## Prerequisites

- Kubernetes 1.28+
- Helm 3.12+

## Installation

### Install CRDs (Required First)

```bash
helm install butler-crds oci://ghcr.io/butlerdotdev/charts/butler-crds \
  --namespace butler-system \
  --create-namespace
```

### Upgrade CRDs

```bash
helm upgrade butler-crds oci://ghcr.io/butlerdotdev/charts/butler-crds \
  --namespace butler-system
```

### Uninstall

By default, CRDs are retained on uninstall to prevent data loss:

```bash
# This will NOT delete CRDs (safe)
helm uninstall butler-crds -n butler-system

# To force CRD deletion (DANGER: deletes all Butler resources!)
helm uninstall butler-crds -n butler-system
kubectl delete crd -l app.kubernetes.io/name=butler-crds
```

## CRDs Included

| CRD | API Group | Description |
|-----|-----------|-------------|
| ClusterBootstrap | butler.butlerlabs.dev | Management cluster creation workflow |
| MachineRequest | butler.butlerlabs.dev | VM provisioning interface for providers |
| ProviderConfig | butler.butlerlabs.dev | Infrastructure provider configuration |
| TenantCluster | butler.butlerlabs.dev | Tenant cluster lifecycle management |
| TenantAddon | butler.butlerlabs.dev | Addon installation and management |
| Team | butler.butlerlabs.dev | Multi-tenancy and RBAC |
| ButlerConfig | butler.butlerlabs.dev | Platform-wide configuration |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotations | object | `{}` | Annotations to add to all CRDs |
| labels | object | `{}` | Labels to add to all CRDs |
| crds.clusterBootstrap | bool | `true` | Install ClusterBootstrap CRD |
| crds.machineRequest | bool | `true` | Install MachineRequest CRD |
| crds.providerConfig | bool | `true` | Install ProviderConfig CRD |
| crds.tenantCluster | bool | `true` | Install TenantCluster CRD |
| crds.tenantAddon | bool | `true` | Install TenantAddon CRD |
| crds.team | bool | `true` | Install Team CRD |
| crds.butlerConfig | bool | `true` | Install ButlerConfig CRD |
| keep | bool | `true` | Keep CRDs on chart uninstall |

## Versioning

CRD versions follow the Kubernetes API versioning convention:

- `v1alpha1` - Initial development, breaking changes expected
- `v1beta1` - API stabilizing, deprecation notices for changes
- `v1` - Stable API, backward compatible changes only

Current API version: **v1alpha1**

## Upgrading

### From 0.x to 0.y

CRD upgrades are generally safe as Kubernetes handles schema evolution. However:

1. Always backup your resources before upgrading
2. Review release notes for breaking changes
3. Test in non-production first

```bash
# Backup existing resources
kubectl get clusterbootstraps,machinerequests,providerconfigs -A -o yaml > butler-backup.yaml

# Upgrade CRDs
helm upgrade butler-crds oci://ghcr.io/butlerdotdev/charts/butler-crds
```

## Troubleshooting

### CRDs not installing

Check Helm permissions:
```bash
kubectl auth can-i create customresourcedefinitions --as=system:serviceaccount:kube-system:helm
```

### Resources not validating

Ensure CRD is established:
```bash
kubectl get crd clusterbootstraps.butler.butlerlabs.dev -o jsonpath='{.status.conditions[?(@.type=="Established")].status}'
```

## License

Apache License 2.0
