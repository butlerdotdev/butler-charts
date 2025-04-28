# Butler Helm Charts

Welcome to the Helm chart repository for **Butler**, the enterprise Kubernetes-native cluster orchestration platform.  
This repository houses Helm charts for bootstrapping and managing Butler's management cluster and tenant clusters.

---

## Table of Contents

- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Management Chart Components](#management-chart-components)
- [Requirements](#requirements)
- [Secret Management](#secret-management)
- [Best Practices](#best-practices)
- [Development](#development)
- [Future Work](#future-work)
- [License](#license)
- [Contributions](#contributions)

---

## Repository Structure

| Path | Description |
|:---|:---|
| `charts/butler-mgmt/` | Helm chart for bootstrapping the Butler Management Cluster |
| `charts/butler-tenant/` | (Planned) Helm chart for bootstrapping Butler-managed Tenant Clusters |
| `charts/...` | Future charts for extensions, observability, integrations |

---

## Quick Start

Clone the repository:

```bash
git clone https://github.com/butlerdotdev/butler-charts.git
cd butler-charts
```

Install Butler Management Chart manually:

```bash
helm dependency update charts/butler-mgmt
helm install butler-mgmt ./charts/butler-mgmt -f charts/butler-mgmt/values.yaml
```

Or install using GitOps (FluxCD) by referencing this chart in a `HelmRelease`.

---

## Management Chart Components

The `butler-mgmt` chart deploys:

- **Cluster API Operator** (CAPI)
- **Cert-Manager**
- **Kamaji** (Tenant Control Plane Provider)
- **MetalLB** (LoadBalancer for bare metal)
- **Traefik** (Ingress Controller)
- **Optional Observability Stack** (Planned)

Installation flow respects dependency ordering with Helm hooks and readiness checks.

---

## Requirements

- Kubernetes 1.26+
- Helm 3.9+
- Optional: FluxCD for GitOps workflows
- Pre-installed:
  - LINSTOR Operator (if used for storage)
  - Flux bootstrap (if using GitOps mode)

---

## Secret Management

Secrets such as Nutanix infrastructure credentials are handled via:

- Helm templated secrets
- Optional integration with external secrets managers (Vault, SOPS)
- Configuration via `values.yaml` (with secure overrides)

---

## Best Practices

- Always run `helm dependency update` before installing.
- Keep `values.yaml` environment-specific for flexibility.
- Use GitOps where possible for production.
- Separate tenant cluster management using `butler-tenant` chart (coming soon).

---

## Development

Lint charts:

```bash
helm lint charts/butler-mgmt
```

Package chart:

```bash
helm package charts/butler-mgmt
```

Template and verify output:

```bash
helm template butler-mgmt ./charts/butler-mgmt
```

---

## Future Work

- Observability chart (Prometheus Operator, Grafana Agent, Loki)
- Tenant cluster bootstrap (`butler-tenant` chart)
- Extended provider integrations (AWS, Azure, VMware)
- Automatic cluster upgrades and lifecycle workflows

---

## License

This repository is licensed under the [Apache 2.0 License](LICENSE).

---

## Contributions

Contributions are welcome! Please open an Issue or Pull Request.

---

