# Monitoring Guide

## Overview

The AKS Landing Zone Lab uses a layered monitoring approach:

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Phase 1 (Core)** | Log Analytics + Container Insights | Central logging, pod/node metrics, KQL queries |
| **Phase 2 (Advanced)** | Managed Prometheus + Grafana | Custom metrics, dashboards, long-term storage |
| **Alerting** | Azure Monitor Alerts | Proactive notification on failures and threshold breaches |

Phase 1 is always deployed. Phase 2 components are enabled via optional toggles (`enable_managed_prometheus`, `enable_managed_grafana`).

---

## Phase 1: Log Analytics & Container Insights

### Architecture

```
AKS Cluster
  ├── OMS Agent (DaemonSet)
  │     └── Collects container logs, metrics, inventory
  ├── Diagnostic Settings
  │     └── API server, controller-manager, scheduler, autoscaler, audit, guard
  └── NSG Flow Logs
        └── Network traffic analytics

All data → Log Analytics Workspace (law-aks-{env})
             └── 30-day retention
             └── Daily cap: configurable (default: no cap)
```

### What Container Insights Collects

- **Container logs**: stdout/stderr from all containers
- **Performance data**: CPU, memory, disk, network per node and pod
- **Inventory**: Pod, container, node, and deployment metadata
- **Kubernetes events**: Scheduling, scaling, failures
- **Live metrics**: Real-time streaming in Azure Portal

### Accessing Container Insights

1. Navigate to Azure Portal → your AKS cluster → **Insights**
2. Use these tabs:
   - **Cluster**: Overall CPU/memory utilization per node
   - **Nodes**: Individual node health, resource consumption
   - **Controllers**: Deployment replica status
   - **Containers**: Per-container CPU, memory, restarts
   - **Live Logs**: Real-time log streaming

---

## KQL Query Cookbook

### Pod & Container Queries

**Pods with restarts in the last 24 hours**:
```kql
KubePodInventory
| where TimeGenerated > ago(24h)
| where RestartCount > 0
| summarize MaxRestarts = max(RestartCount) by Namespace, Name, ContainerName
| order by MaxRestarts desc
```

**Pods stuck in non-Running state**:
```kql
KubePodInventory
| where TimeGenerated > ago(1h)
| where PodStatus !in ("Running", "Succeeded")
| summarize arg_max(TimeGenerated, *) by Name, Namespace
| project TimeGenerated, Namespace, Name, PodStatus, ContainerStatus
| order by TimeGenerated desc
```

**OOMKilled events**:
```kql
KubeEvents
| where TimeGenerated > ago(24h)
| where Reason == "OOMKilling"
| project TimeGenerated, Namespace, Name, Message
| order by TimeGenerated desc
```

**Container log search (hello-web)**:
```kql
ContainerLogV2
| where TimeGenerated > ago(1h)
| where PodName startswith "hello-web"
| project TimeGenerated, PodName, ContainerName, LogMessage, LogLevel
| order by TimeGenerated desc
| take 100
```

**Container log errors (all pods)**:
```kql
ContainerLogV2
| where TimeGenerated > ago(6h)
| where LogLevel in ("error", "ERROR", "fatal", "FATAL")
| summarize ErrorCount = count() by PodName, Namespace, bin(TimeGenerated, 15m)
| order by ErrorCount desc
| render timechart
```

### Node Queries

**Node CPU utilization**:
```kql
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "K8SNode"
| where CounterName == "cpuUsageNanoCores"
| extend CPUPercent = CounterValue / 1000000000 * 100
| summarize AvgCPU = avg(CPUPercent) by Computer, bin(TimeGenerated, 5m)
| render timechart
```

**Node memory utilization**:
```kql
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "K8SNode"
| where CounterName == "memoryRssBytes"
| extend MemoryMB = CounterValue / 1048576
| summarize AvgMemMB = avg(MemoryMB) by Computer, bin(TimeGenerated, 5m)
| render timechart
```

**Nodes not ready**:
```kql
KubeNodeInventory
| where TimeGenerated > ago(1h)
| where Status != "Ready"
| summarize arg_max(TimeGenerated, *) by Computer
| project TimeGenerated, Computer, Status, KubernetesProviderID
```

### API Server Queries

**API server errors (5xx)**:
```kql
AzureDiagnostics
| where Category == "kube-apiserver"
| where TimeGenerated > ago(1h)
| where log_s contains "statusCode\":5"
| project TimeGenerated, log_s
| order by TimeGenerated desc
| take 50
```

**API server request latency**:
```kql
AzureDiagnostics
| where Category == "kube-apiserver"
| where TimeGenerated > ago(1h)
| where log_s contains "requestLatency"
| parse log_s with * "requestLatency\":" latency:long *
| where latency > 1000
| project TimeGenerated, latency, log_s
| order by latency desc
```

**Audit log: who deleted what**:
```kql
AzureDiagnostics
| where Category == "kube-audit-admin"
| where TimeGenerated > ago(24h)
| where log_s contains "\"verb\":\"delete\""
| project TimeGenerated, log_s
| order by TimeGenerated desc
```

### Cluster Autoscaler Queries

**Autoscaler scale-up events**:
```kql
AzureDiagnostics
| where Category == "cluster-autoscaler"
| where TimeGenerated > ago(24h)
| where log_s contains "ScaledUp" or log_s contains "ScaleUp"
| project TimeGenerated, log_s
| order by TimeGenerated desc
```

**Autoscaler unschedulable pods**:
```kql
AzureDiagnostics
| where Category == "cluster-autoscaler"
| where TimeGenerated > ago(24h)
| where log_s contains "unschedulable"
| project TimeGenerated, log_s
| order by TimeGenerated desc
```

### Network Queries

**NSG flow logs - denied traffic**:
```kql
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(1h)
| where FlowStatus_s == "D"
| summarize DeniedCount = count() by NSGRG = NSGList_s, bin(TimeGenerated, 15m)
| render timechart
```

**DNS resolution failures**:
```kql
ContainerLogV2
| where TimeGenerated > ago(6h)
| where LogMessage contains "NXDOMAIN" or LogMessage contains "SERVFAIL"
| project TimeGenerated, PodName, LogMessage
| order by TimeGenerated desc
```

---

## Alert Configuration

### Alert Rules Deployed

| Alert | Type | Condition | Severity |
|-------|------|-----------|----------|
| Node NotReady | Metric | Node status != Ready | Sev 1 |
| Node CPU > 80% | Metric | Avg CPU > 80% for 5 min | Sev 2 |
| Node Memory > 80% | Metric | Avg Memory > 80% for 5 min | Sev 2 |
| Pod restart > 5 | Metric | Restart count > 5 in 10 min | Sev 2 |
| Failed pod count > 0 | Metric | Failed pods > 0 | Sev 2 |
| OOMKilled events | Log | KubeEvents Reason == OOMKilling | Sev 2 |
| API server 5xx | Log | kube-apiserver 5xx responses | Sev 1 |
| Image pull failure | Log | Container image pull errors | Sev 3 |
| Budget threshold | Budget | Spend > $100 (configurable) | Sev 3 |
| Log ingestion cap | Metric | Daily cap approaching | Sev 3 |

### Action Group

All alerts route to the configured Action Group with an email receiver:

```hcl
variable "alert_email" {
  default = "admin@example.com"
}
```

### Testing Alerts

Deploy these manifests to deliberately trigger alerts:

```powershell
# Trigger restart alert
kubectl apply -f k8s/apps/crashloop-pod.yaml

# Trigger CPU alert
kubectl apply -f k8s/apps/stress-cpu.yaml

# Trigger OOM alert
kubectl apply -f k8s/apps/stress-memory.yaml
```

Allow 5–10 minutes for alert evaluation and notification delivery.

---

## Phase 2: Prometheus & Grafana (Optional)

Enable in `environments/lab.tfvars`:
```hcl
enable_managed_prometheus = true   # +$0-5/mo
enable_managed_grafana    = true   # +$10/mo
```

### What This Adds

- **Azure Monitor Workspace** for Prometheus data storage
- **Managed Prometheus** data collection rules and endpoints
- **Managed Grafana** instance with Azure AD authentication
- **Pre-built dashboards**: Cluster, Nodes, Pods, Ingress, PV Usage

### Custom Metrics Scraping

The `metrics-app` workload exposes a `/metrics` endpoint. The Prometheus scrape config in `k8s/monitoring/prometheus-scrape-config.yaml` picks up any pod annotated with:

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"
```

### Grafana Dashboard Walkthrough

After enabling Grafana, access it at the endpoint shown in the Terraform output:

```powershell
terraform output grafana_endpoint
```

Default dashboards:
1. **Kubernetes / Cluster** – Overview of cluster-wide metrics
2. **Kubernetes / Nodes** – Per-node CPU, memory, disk, network
3. **Kubernetes / Pods** – Pod resource consumption and restarts
4. **NGINX Ingress** – Request rate, latency, error rate
5. **Persistent Volumes** – PV usage and available capacity

---

## Diagnostic Settings Reference

### AKS Cluster Logs

| Log Category | Description |
|---|---|
| `kube-apiserver` | API server requests and responses |
| `kube-controller-manager` | Controller manager operations |
| `kube-scheduler` | Pod scheduling decisions |
| `kube-audit-admin` | Audit logs for write operations |
| `guard` | Azure AD and RBAC audit |
| `cluster-autoscaler` | Autoscaler scaling decisions |

### NSG Flow Logs

NSG Flow Logs v2 capture all allowed and denied network flows through NSGs. Traffic analytics processes these logs in Log Analytics with 10-minute intervals for near-real-time visibility.

---

## Troubleshooting Monitoring Issues

| Issue | Resolution |
|-------|-----------|
| No data in Container Insights | Check OMS agent pods: `kubectl get pods -n kube-system -l component=oms-agent` |
| KQL queries return empty | Verify diagnostic settings are enabled; data may take 5–15 min to appear |
| Alerts not firing | Check Action Group configuration and alert rule evaluation frequency |
| Grafana not accessible | Verify `enable_managed_grafana = true` and check Azure AD permissions |
| High Log Analytics costs | Set `log_analytics_daily_quota_gb` to cap daily ingest; review diagnostic log categories |
