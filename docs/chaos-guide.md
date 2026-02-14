# Chaos Engineering Guide

## Overview

Chaos engineering deliberately introduces failures into a system to test its resilience and verify that monitoring and alerting work correctly. This lab uses [Chaos Mesh](https://chaos-mesh.org/) — a CNCF project — to run controlled experiments on the AKS cluster.

### Goals
- Verify that Kubernetes self-heals after pod failures
- Confirm that alerts fire when unexpected events occur
- Build confidence in the system's ability to recover
- Practice incident response procedures

---

## Chaos Mesh Setup

### Prerequisites
- AKS cluster running with workloads deployed
- Helm 3.x installed
- kubectl connected to the cluster

### Installation

```powershell
# Add the Chaos Mesh Helm repo
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

# Install Chaos Mesh with lab-specific values
helm install chaos-mesh chaos-mesh/chaos-mesh `
  --namespace chaos-testing `
  --create-namespace `
  -f k8s/chaos/chaos-mesh-values.yaml `
  --version 2.7.0

# Verify installation
kubectl get pods -n chaos-testing
```

**Expected**: 3 pods running:
- `chaos-controller-manager-*`
- `chaos-daemon-*` (one per node)
- `chaos-dashboard-*`

### Accessing the Dashboard (Optional)

```powershell
# Port-forward the Chaos Mesh dashboard
kubectl port-forward -n chaos-testing svc/chaos-dashboard 2333:2333

# Open in browser: http://localhost:2333
```

---

## Experiment 1: Pod Kill

### Description
Randomly kills one pod in the `lab-apps` namespace every 5 minutes. This simulates unexpected pod crashes (node failure, OOM, application crash) and verifies that Kubernetes restarts the pod automatically.

### Experiment Configuration

The experiment is defined in `k8s/chaos/pod-kill-experiment.yaml`:
- **Action**: `pod-kill` — sends SIGKILL to a random pod
- **Mode**: `one` — kills one pod at a time
- **Selector**: All pods in `lab-apps` with label `environment: lab`, excluding stress/crashloop pods
- **Duration**: 30 seconds (time between kill and observation)
- **Schedule**: Every 5 minutes

### Steps

#### Step 1: Verify Baseline State

```powershell
# Record current pod state
kubectl get pods -n lab-apps -o wide
kubectl get deployments -n lab-apps

# Note hello-web should have 2/2 replicas ready
```

#### Step 2: Apply the Experiment

```powershell
kubectl apply -f k8s/chaos/pod-kill-experiment.yaml

# Verify experiment is active
kubectl get podchaos -n lab-apps
```

#### Step 3: Observe the Chaos

```powershell
# Watch pods in real-time (you'll see pods terminate and restart)
kubectl get pods -n lab-apps -w

# In a separate terminal, watch events
kubectl get events -n lab-apps --sort-by='.lastTimestamp' -w
```

**Expected behavior**:
1. One pod is killed (disappears from `Running` state)
2. Kubernetes detects the pod is gone (within seconds)
3. ReplicaSet controller creates a replacement pod
4. New pod goes through `Pending → ContainerCreating → Running`
5. Total recovery time: 10–30 seconds

#### Step 4: Check Monitoring

```powershell
# After 5–10 minutes, check for alerts
# Azure Portal → Monitor → Alerts

# KQL query for restart events
# KubePodInventory
# | where TimeGenerated > ago(30m)
# | where Namespace == "lab-apps"
# | where RestartCount > 0
# | project TimeGenerated, Name, RestartCount
```

Expected alerts:
- **Pod restart count > 5 in 10 min** (after ~25 minutes of the experiment running)

#### Step 5: Stop the Experiment

```powershell
kubectl delete -f k8s/chaos/pod-kill-experiment.yaml

# Verify all pods recovered
kubectl get pods -n lab-apps
kubectl get deployments -n lab-apps
```

### Recovery Verification

| Check | Command | Expected |
|-------|---------|----------|
| All pods running | `kubectl get pods -n lab-apps` | All `Running`, `READY` = desired |
| No pending pods | `kubectl get pods -n lab-apps --field-selector=status.phase=Pending` | No results |
| Deployment healthy | `kubectl rollout status deploy/hello-web -n lab-apps` | `successfully rolled out` |
| Service responding | `curl http://<ingress-ip> -H "Host: hello-web.local"` | HTTP 200 |

---

## Experiment 2: Network Delay

### Description
Injects network latency (100ms delay) on all pods in the `lab-apps` namespace. This simulates network degradation (congested links, cross-region latency, DNS slowness) and tests how the application handles increased response times.

### Experiment Configuration

The experiment is defined in `k8s/chaos/network-delay-experiment.yaml`:
- **Action**: `delay` — adds latency to network packets
- **Latency**: 100ms (configurable)
- **Jitter**: 25ms (variation in delay)
- **Correlation**: 50% of packets affected
- **Duration**: 2 minutes

### Steps

#### Step 1: Measure Baseline Latency

```powershell
# Measure response time to hello-web from within the cluster
kubectl run latency-test -n lab-apps --image=busybox:1.36 --restart=Never -- /bin/sh -c "
  i=0; while [ \$i -lt 5 ]; do
    start=\$(date +%s%N)
    wget -qO- --timeout=5 http://hello-web.lab-apps.svc.cluster.local > /dev/null 2>&1
    end=\$(date +%s%N)
    echo \"Request \$i: \$(( (end - start) / 1000000 ))ms\"
    i=\$((i + 1))
  done
"
kubectl logs latency-test -n lab-apps
kubectl delete pod latency-test -n lab-apps
```

**Expected baseline**: 1–5ms response time.

#### Step 2: Apply the Network Delay Experiment

```powershell
kubectl apply -f k8s/chaos/network-delay-experiment.yaml

# Verify experiment is active
kubectl get networkchaos -n lab-apps
```

#### Step 3: Measure Latency Under Chaos

```powershell
# Re-run the latency test
kubectl run latency-test -n lab-apps --image=busybox:1.36 --restart=Never -- /bin/sh -c "
  i=0; while [ \$i -lt 5 ]; do
    start=\$(date +%s%N)
    wget -qO- --timeout=10 http://hello-web.lab-apps.svc.cluster.local > /dev/null 2>&1
    end=\$(date +%s%N)
    echo \"Request \$i: \$(( (end - start) / 1000000 ))ms\"
    i=\$((i + 1))
  done
"
kubectl logs latency-test -n lab-apps
kubectl delete pod latency-test -n lab-apps
```

**Expected**: Response times increase to 100–130ms (baseline + 100ms delay ± 25ms jitter).

#### Step 4: Observe Impact on Probes

```powershell
# Check if liveness/readiness probes are affected
kubectl describe pods -n lab-apps -l app=hello-web | Select-String -Pattern "Liveness|Readiness|Warning"

# If delay is high enough, probes may fail temporarily
kubectl get events -n lab-apps --field-selector reason=Unhealthy
```

#### Step 5: Stop the Experiment

```powershell
kubectl delete -f k8s/chaos/network-delay-experiment.yaml

# Verify latency returns to normal
kubectl run latency-test -n lab-apps --image=busybox:1.36 --restart=Never -- /bin/sh -c "
  wget -qO- --timeout=5 http://hello-web.lab-apps.svc.cluster.local > /dev/null 2>&1
  echo 'Latency back to normal'
"
kubectl logs latency-test -n lab-apps
kubectl delete pod latency-test -n lab-apps
```

### Recovery Verification

| Check | Command | Expected |
|-------|---------|----------|
| Normal latency | Run latency test above | < 5ms |
| No probe failures | `kubectl get events -n lab-apps --field-selector reason=Unhealthy` | No recent events |
| Pods healthy | `kubectl get pods -n lab-apps` | All `Running`, no restarts |

---

## Recovery Verification Procedures

After any chaos experiment, follow this standard recovery checklist:

### Immediate Checks (0–5 minutes after stopping experiment)

```powershell
# 1. All pods are running
kubectl get pods -n lab-apps
# Expected: All pods Running, READY = desired count

# 2. No pending pods
kubectl get pods -A --field-selector=status.phase=Pending
# Expected: No results

# 3. Deployments are healthy
kubectl get deployments -n lab-apps
# Expected: READY column matches DESIRED

# 4. Services have endpoints
kubectl get endpoints -n lab-apps
# Expected: All services have IP addresses listed

# 5. Ingress is serving traffic
$ingressIP = kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
curl "http://$ingressIP" -H "Host: hello-web.local" -w "\nHTTP Status: %{http_code}\n"
# Expected: HTTP 200
```

### Extended Checks (5–15 minutes after stopping experiment)

```powershell
# 6. No crash loops
kubectl get pods -n lab-apps -o jsonpath='{range .items[*]}{.metadata.name}{"  Restarts: "}{.status.containerStatuses[0].restartCount}{"\n"}{end}'
# Expected: Restart count is stable (not increasing)

# 7. Metrics are flowing
kubectl top pods -n lab-apps
# Expected: CPU/memory values for all pods

# 8. Alerts cleared
# Check Azure Portal → Monitor → Alerts → make sure no active firing alerts
```

---

## Runbook Template

Use this template to document chaos experiments in your team's runbook:

```markdown
# Chaos Experiment Runbook: [Experiment Name]

## Metadata
- **Date**: YYYY-MM-DD
- **Operator**: [Name]
- **Duration**: [X minutes]
- **Target**: [Namespace/pods affected]

## Hypothesis
[What do you expect to happen? e.g., "When we kill one hello-web pod, the ReplicaSet
will create a replacement within 30 seconds and the service will remain available."]

## Pre-Experiment State
- Pods: [count] running in [namespace]
- Nodes: [count] Ready
- Alerts: [none firing / list active]

## Experiment Execution
1. Applied experiment at HH:MM
2. Observed: [what happened]
3. Stopped experiment at HH:MM

## Observations
- Recovery time: [X seconds]
- Alerts fired: [list]
- User impact: [none / degraded / outage]
- Unexpected behavior: [none / describe]

## Post-Experiment State
- All pods recovered: [Yes/No]
- Services healthy: [Yes/No]
- Alerts cleared: [Yes/No]

## Conclusions
[What did we learn? Any improvements needed?]

## Action Items
- [ ] [Action item 1]
- [ ] [Action item 2]
```

---

## Safety Guidelines

1. **Always scope experiments to lab namespaces** — never target `kube-system` or `ingress-nginx`
2. **Start small** — one pod at a time, short durations
3. **Have a rollback plan** — know how to delete the experiment quickly
4. **Monitor actively** — watch pods and alerts in real-time during experiments
5. **Document everything** — use the runbook template for each experiment
6. **Don't run experiments against a stopped cluster** — ensure all workloads are healthy first
