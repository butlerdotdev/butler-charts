# Butler Monitoring

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Substrate health monitoring for Butler management clusters.

## Overview

Butler Monitoring deploys Prometheus and a set of scrape targets, recording rules, and alert rules for the substrates that make up a Butler management cluster. It answers the question: "Is the infrastructure backing my tenants healthy?"

Substrates monitored:

- **Steward etcd** — shared etcd instances backing tenant control planes. This is the highest-priority signal: a stressed etcd instance cascades failures across every tenant sharing it.
- **Management etcd** — the management cluster's own etcd, backing butler-controller, butler-server, and Steward.
- **butler-controller** — reconcile health, workqueue depth, and controller-runtime metrics.
- **Steward** — tenant control plane lifecycle controller metrics.
- **butler-server** — console API metrics (disabled by default; instrumentation not yet shipped).
- **Tenant control planes** — per-tenant kube-apiserver, kube-controller-manager, and kube-scheduler metrics (disabled by default; auth prerequisite pending upstream).

## Prerequisites

- Kubernetes 1.28+
- Helm 3.12+
- Prometheus Operator CRDs (installed automatically by the kube-prometheus-stack subchart)

## Installation

```bash
helm install butler-monitoring oci://ghcr.io/butlerdotdev/charts/butler-monitoring \
  --namespace monitoring-system \
  --create-namespace
```

Management etcd requires static addresses (it runs outside Kubernetes workload scheduling):

```bash
helm install butler-monitoring oci://ghcr.io/butlerdotdev/charts/butler-monitoring \
  --namespace monitoring-system \
  --create-namespace \
  --set 'substrates.managementEtcd.addresses[0]=10.0.0.1' \
  --set 'substrates.managementEtcd.addresses[1]=10.0.0.2' \
  --set 'substrates.managementEtcd.addresses[2]=10.0.0.3' \
  --set substrates.managementEtcd.tlsConfig.certSecretName=etcd-client-certs
```

## Architecture

The chart wraps [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) as a subchart for Prometheus and the Prometheus Operator. Butler-specific scrape targets, recording rules, and alert rules are layered on top.

```
butler-monitoring
├── kube-prometheus-stack (subchart)
│   ├── Prometheus Operator
│   └── Prometheus server
├── ServiceMonitors / PodMonitor (scrape targets)
├── PrometheusRule — recording rules (pre-computed quantiles)
└── PrometheusRule — alert rules (substrate health alerts)
```

Default kube-prometheus-stack exporters (node-exporter, kube-state-metrics, kubelet, etc.) are disabled. Butler monitors specific substrate targets; cluster-level observability is expected to come from a separate stack if needed.

## Scrape Targets

### Steward etcd

Enabled by default. Scrapes the etcd metrics port (2381) over plain HTTP. Selects the steward-etcd client service by the label `prometheus.io/metrics: "true"` (configurable via `substrates.stewardEtcd.matchLabels`).

Metrics collected include WAL fsync and backend commit histograms, leader state, proposal counters, database size, peer network failures, and process resource usage. A keep-list filters to these specific metrics to control cardinality.

### Management etcd

Enabled by default, but **no resources are created** unless `substrates.managementEtcd.addresses` is populated. Management cluster etcd typically runs outside Kubernetes workload scheduling (systemd on control plane nodes, Talos machine config, etc.), so the chart creates a headless Service + Endpoints pair with static IP addresses, then a ServiceMonitor pointing at them.

Most management etcd deployments require mTLS. Create a Secret containing the client certificate, key, and CA:

```bash
kubectl create secret generic etcd-client-certs \
  --namespace monitoring-system \
  --from-file=ca.crt=/path/to/ca.crt \
  --from-file=tls.crt=/path/to/client.crt \
  --from-file=tls.key=/path/to/client.key
```

Then reference it:

```yaml
substrates:
  managementEtcd:
    addresses: ["10.0.0.1", "10.0.0.2", "10.0.0.3"]
    tlsConfig:
      certSecretName: etcd-client-certs
```

**Topology examples:**

| Platform | How to find etcd addresses |
|----------|---------------------------|
| kubeadm | `kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'` |
| Talos | `talosctl get endpoints -n <control-plane-node>` |
| k3s (embedded) | Management etcd is SQLite; this target does not apply |
| External etcd | Use the advertised client URLs from etcd configuration |

### butler-controller

Enabled by default. Scrapes controller-runtime metrics (port 8080) over HTTP. Selects by `app.kubernetes.io/name: butler-controller`.

Metrics include reconcile duration histograms, reconcile error counts, workqueue depth, and any `butler_*` custom metrics from the controller.

### Steward

Enabled by default. Scrapes controller-runtime metrics (port 8080) over HTTP. Selects by `app.kubernetes.io/name: steward`.

### butler-server

**Disabled by default.** butler-server does not yet expose a `/metrics` endpoint. The ServiceMonitor is scaffolded so that enabling it after instrumentation ships requires only `--set substrates.butlerServer.enabled=true`.

### Tenant control planes

**Disabled by default.** Each tenant's kube-apiserver, kube-controller-manager, and kube-scheduler run as containers in a single pod on the management cluster. The PodMonitor discovers these pods via `steward.butlerlabs.dev/component: deployment` and scrapes each container's metrics port.

**Auth prerequisite:** Tenant CP components authenticate via per-tenant mTLS client certificates. A PodMonitor's `tlsConfig` is per-endpoint, not per-pod, so a single PodMonitor cannot reference different certs for different tenants. Scrapes return 401/403 until one of:

- Steward provisions a shared monitoring credential
- butler-controller creates per-tenant ServiceMonitors dynamically

The PodMonitor is shipped with discovery, relabeling, and metric filtering in place. When the auth prerequisite is resolved upstream, it activates by setting `substrates.tenantControlPlanes.enabled: true`. Recording rules and alert rules that reference tenant CP metrics produce no output when no matching series exist and activate automatically when data becomes available.

See [butlerdotdev/butler-charts#106](https://github.com/butlerdotdev/butler-charts/issues/106) for upstream tracking.

**Cardinality note:** Tenant CP scraping adds series proportional to the number of tenants. The keep-lists on each endpoint filter to operationally critical metrics:

| Endpoint | Metrics kept |
|----------|-------------|
| kube-apiserver | `apiserver_request_total`, `apiserver_request_duration_seconds_bucket`, `apiserver_current_inflight_requests`, `apiserver_storage_objects`, process metrics, workqueue metrics |
| kube-controller-manager | `workqueue_depth`, `workqueue_adds_total`, process metrics |
| kube-scheduler | `scheduler_scheduling_attempt_duration_seconds_bucket`, `scheduler_pending_pods`, process metrics |

For 50+ tenant installations, monitor `prometheus_tsdb_head_series` and consider tightening the keep-lists or reducing scrape frequency.

### Duplicate scrape note

Both butler-controller and Steward have ServiceMonitors in their own charts (`metrics.serviceMonitor.enabled` / `serviceMonitor.enabled`, disabled by default). If you enable those alongside butler-monitoring's ServiceMonitors, Prometheus will scrape the same endpoints twice. This doubles cardinality for those metrics but does not cause correctness issues — recording rules filter by `substrate` label, which is only injected by butler-monitoring's relabelings.

If both are enabled, disable the component chart's ServiceMonitor (not butler-monitoring's). Recording rules and alerts depend on the `substrate` label that butler-monitoring's relabelings inject. Keeping only the component chart's monitor will break all recording rules and alerts for that substrate.

## Recording Rules

19 recording rules across 5 groups pre-compute histogram quantiles and rates so that dashboards and alerts query single-value gauges instead of raw histogram buckets. All rules use a 30-second evaluation interval and 5-minute rate windows.

| Group | Rules | Key metrics |
|-------|-------|-------------|
| `butler:steward-etcd` | 5 | WAL fsync p99, backend commit p99, proposal failure rate, proposal apply lag, database size |
| `butler:management-etcd` | 5 | Same as steward-etcd, differentiated by `substrate` label |
| `butler:controller` | 3 | Reconcile duration p99, reconcile error ratio, workqueue depth |
| `butler:steward` | 3 | Reconcile duration p99, reconcile error ratio, workqueue depth |
| `butler:tenant-cp` | 3 | Apiserver latency p99, apiserver error rate, inflight requests |

## Alert Rules

19 alert rules across 5 groups. Alerts evaluate in Prometheus regardless of whether Alertmanager is configured. When Alertmanager is enabled, these rules begin routing immediately.

**Alertmanager is not deployed by default.** Alerts are visible only in the Prometheus UI at `/alerts`. No notifications (PagerDuty, Slack, email) are sent. Operators must check the Prometheus UI manually or deploy Alertmanager separately to receive notifications.

### Steward etcd alerts

| Alert | Severity | Threshold | For |
|-------|----------|-----------|-----|
| `StewardEtcdNoLeader` | critical | `etcd_server_has_leader == 0` | 1m |
| `StewardEtcdHighLeaderChanges` | warning | Leader changes in 15m > 3 | 5m |
| `StewardEtcdWalFsyncSlow` | warning | WAL fsync p99 > 50ms | 5m |
| `StewardEtcdWalFsyncCritical` | critical | WAL fsync p99 > 200ms | 5m |
| `StewardEtcdBackendCommitSlow` | warning | Backend commit p99 > 25ms | 5m |
| `StewardEtcdProposalFailures` | critical | Proposal failure rate > 0 | 5m |
| `StewardEtcdDbSizeWarning` | warning | Database size > 1.5 GiB | 5m |

### Management etcd alerts

| Alert | Severity | Threshold | For |
|-------|----------|-----------|-----|
| `ManagementEtcdNoLeader` | critical | `etcd_server_has_leader == 0` | 1m |
| `ManagementEtcdWalFsyncSlow` | warning | WAL fsync p99 > 50ms | 5m |
| `ManagementEtcdWalFsyncCritical` | critical | WAL fsync p99 > 200ms | 5m |
| `ManagementEtcdProposalFailures` | critical | Proposal failure rate > 0 | 5m |

### butler-controller alerts

| Alert | Severity | Threshold | For |
|-------|----------|-----------|-----|
| `ButlerControllerReconcileErrors` | warning | Error ratio > 5% | 5m |
| `ButlerControllerReconcileErrorsCritical` | critical | Error ratio > 25% | 5m |
| `ButlerControllerWorkqueueBacklog` | warning | Queue depth > 50 | 10m |

### Steward alerts

| Alert | Severity | Threshold | For |
|-------|----------|-----------|-----|
| `StewardReconcileErrors` | warning | Error ratio > 5% | 5m |
| `StewardReconcileErrorsCritical` | critical | Error ratio > 25% | 5m |

### Tenant control plane alerts

| Alert | Severity | Threshold | For |
|-------|----------|-----------|-----|
| `TenantApiserverLatencyWarning` | warning | Read latency p99 > 1s | 5m |
| `TenantApiserverLatencyCritical` | critical | Read latency p99 > 5s | 5m |
| `TenantApiserverErrors` | warning | 5xx error rate > 0.5/s | 5m |

### Tuning thresholds

All alert thresholds are exposed in `values.yaml` under `alertRules.thresholds` and can be adjusted via `helm upgrade --set` without forking the chart:

```bash
# Tighten WAL fsync warning for NVMe-backed clusters
helm upgrade butler-monitoring ... \
  --set alertRules.thresholds.stewardEtcd.walFsyncWarning=0.01

# Relax controller error ratio for noisy environments
helm upgrade butler-monitoring ... \
  --set alertRules.thresholds.controller.reconcileErrorWarning=0.10
```

Default thresholds are calibrated for moderate-sized installations (10-30 tenants, typical hardware). Small installations can relax thresholds; large installations with fast storage should tighten them.

## Scaling Guidance

| Installation size | Tenants | Recommended changes |
|-------------------|---------|---------------------|
| Small | < 10 | Reduce `prometheus.prometheusSpec.resources.limits.memory` to 2Gi, reduce storage to 10Gi |
| Moderate | 10-30 | Defaults are sized for this range |
| Large | 50+ | Increase storage to 50Gi+, increase memory limit to 8Gi+, monitor `prometheus_tsdb_head_series`, consider reducing retention or tightening keep-lists |

## Configuration

### Key Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `substrates.butlerController.enabled` | bool | `true` | Scrape butler-controller metrics |
| `substrates.butlerController.namespace` | string | `butler-system` | Namespace where butler-controller is deployed |
| `substrates.butlerServer.enabled` | bool | `false` | Scrape butler-server metrics (requires instrumentation) |
| `substrates.steward.enabled` | bool | `true` | Scrape Steward controller metrics |
| `substrates.steward.namespace` | string | `steward-system` | Namespace where Steward is deployed |
| `substrates.stewardEtcd.enabled` | bool | `true` | Scrape steward-etcd metrics |
| `substrates.stewardEtcd.namespace` | string | `steward-system` | Namespace where steward-etcd is deployed |
| `substrates.managementEtcd.enabled` | bool | `true` | Enable management etcd monitoring (requires addresses) |
| `substrates.managementEtcd.addresses` | list | `[]` | Static IPs for management etcd nodes |
| `substrates.managementEtcd.scheme` | string | `https` | Scrape scheme for management etcd |
| `substrates.managementEtcd.tlsConfig.certSecretName` | string | `""` | Secret with etcd client certs (ca.crt, tls.crt, tls.key) |
| `substrates.tenantControlPlanes.enabled` | bool | `false` | Scrape tenant control plane pods (auth prerequisite pending) |
| `substrates.tenantControlPlanes.apiServerPort` | int | `6443` | kube-apiserver metrics port |
| `substrates.tenantControlPlanes.controllerManagerPort` | int | `10257` | kube-controller-manager metrics port |
| `substrates.tenantControlPlanes.schedulerPort` | int | `10259` | kube-scheduler metrics port |
| `recordingRules.enabled` | bool | `true` | Deploy recording rules |
| `alertRules.enabled` | bool | `true` | Deploy alert rules |
| `alertRules.thresholds.*` | various | see values.yaml | Alert threshold values |
| `kube-prometheus-stack.enabled` | bool | `true` | Deploy kube-prometheus-stack subchart |
| `kube-prometheus-stack.prometheus.prometheusSpec.retention` | string | `7d` | TSDB retention period |
| `kube-prometheus-stack.prometheus.prometheusSpec.retentionSize` | string | `15GiB` | TSDB max size |
| `kube-prometheus-stack.prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage` | string | `20Gi` | Persistent volume size |

See `values.yaml` for the complete configuration reference.

## Coexistence with Existing Prometheus

If your cluster already has kube-prometheus-stack or a standalone Prometheus Operator deployed, butler-monitoring will install a second Prometheus Operator by default. Two operators watching the same CRDs cause reconciliation conflicts.

To use the existing operator:

```yaml
kube-prometheus-stack:
  prometheusOperator:
    enabled: false
```

Butler-monitoring's Prometheus discovers ServiceMonitors and PodMonitors across all namespaces (`serviceMonitorSelectorNilUsesHelmValues: false`). If the existing Prometheus also has namespace-wide discovery, both instances will scrape butler-monitoring's targets. To partition scrape ownership, use label selectors on each Prometheus instance's `serviceMonitorSelector` and `podMonitorSelector`.

CRD version compatibility: kube-prometheus-stack 65.8.1 installs Prometheus Operator CRDs at a specific version. If the existing CRDs are at a different version, Helm may skip CRD installation (Helm does not update CRDs on upgrade). Ensure CRD versions are compatible or manage CRDs separately.

## Troubleshooting

### Prometheus not discovering targets

Verify ServiceMonitors/PodMonitors exist and are in a namespace Prometheus watches:

```bash
kubectl get servicemonitors,podmonitors -n monitoring-system
```

Check that `serviceMonitorSelectorNilUsesHelmValues: false` is set (the chart defaults handle this).

### Management etcd scrapes failing

Check the client certificate Secret exists and has the expected keys:

```bash
kubectl get secret etcd-client-certs -n monitoring-system -o jsonpath='{.data}' | jq 'keys'
# Expected: ["ca.crt", "tls.crt", "tls.key"]
```

Verify the etcd addresses are reachable from the Prometheus pod:

```bash
kubectl exec -n monitoring-system -it prometheus-butler-monitoring-kube-prometheus-stack-prometheus-0 -- \
  wget -q --spider --no-check-certificate https://10.0.0.1:2379/health
```

### Steward etcd ServiceMonitor not matching

The default selector uses `prometheus.io/metrics: "true"`. Verify the steward-etcd client service has this label:

```bash
kubectl get svc -n steward-system -l prometheus.io/metrics=true
```

If the label differs, override via `substrates.stewardEtcd.matchLabels`.

### Checking active alerts

```bash
kubectl port-forward -n monitoring-system svc/butler-monitoring-kube-prometheus-stack-prometheus 9090:9090
# Visit http://localhost:9090/alerts
```

## License

Apache License 2.0
