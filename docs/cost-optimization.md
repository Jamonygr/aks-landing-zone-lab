# Cost Optimization Guide

## Budget Overview

The AKS Landing Zone Lab is designed for a **monthly budget of ~$80–100** with all optional toggles OFF, or **~$55–75** using stop/start scripts.

### Cost Breakdown (Dev Defaults, Always-On)

| Resource | SKU | Monthly Cost | Notes |
|----------|-----|-------------|-------|
| AKS Cluster (control plane) | Free tier | $0.00 | Free for standard usage |
| System Node Pool (1× B2s) | Standard_B2s | ~$30.00 | 2 vCPU, 4 GB RAM |
| User Node Pool (1× B2s) | Standard_B2s | ~$30.00 | 2 vCPU, 4 GB RAM |
| OS Disks (2× 30 GB) | Standard_LRS | ~$3.00 | Per node |
| Public IP (Ingress) | Standard SKU | ~$3.60 | Static allocation |
| Log Analytics Workspace | PerGB2018 | ~$5.00 | ~2 GB/day at $2.76/GB |
| Container Registry | Basic SKU | ~$5.00 | 10 GB storage included |
| Key Vault | Standard | ~$0.00 | Pay per operation (minimal) |
| Load Balancer | Standard | ~$0.00 | Included with AKS |
| NSG Flow Logs | Standard | ~$1.00 | Low traffic volume |
| **Subtotal** | | **~$78** | |

### Optional Toggles Cost Impact

| Toggle | Variable | Monthly Cost | Default |
|--------|----------|-------------|---------|
| Azure Firewall (Basic) | `enable_firewall` | +$900.00 | OFF |
| Managed Prometheus | `enable_managed_prometheus` | +$0–5.00 | OFF |
| Managed Grafana | `enable_managed_grafana` | +$10.00 | OFF |
| Defender for Containers | `enable_defender` | +$7.00/node | OFF |
| Azure DNS Zone | `enable_dns_zone` | +$0.50 | OFF |
| KEDA | `enable_keda` | Free | OFF |
| Azure Files StorageClass | `enable_azure_files` | +$1.00 | OFF |
| Application Insights | `enable_app_insights` | +$0–5.00 | OFF |

### Cost Scenarios

| Scenario | Monthly Cost |
|----------|-------------|
| Dev defaults, always-on | ~$80–100 |
| Dev defaults, stop nights & weekends | ~$55–75 |
| Lab env (monitoring ON, firewall OFF) | ~$105–130 |
| All toggles ON excluding Firewall | ~$105–130 |
| All toggles ON including Firewall | ~$1,000+ |

---

## Stop/Start Schedule

The single most effective cost-saving measure is stopping the AKS cluster when not in use. Stopping the cluster deallocates the node VMs, eliminating compute charges.

### Recommended Schedule

| Period | Action | Savings |
|--------|--------|---------|
| Weeknights (6 PM – 8 AM) | Stop cluster | ~58% of compute |
| Weekends (Fri 6 PM – Mon 8 AM) | Stop cluster | ~29% of compute |
| **Combined** | Stop nights + weekends | **~70% of compute** |

### Using the Scripts

```powershell
# Stop the cluster (saves ~$2/day in compute)
.\scripts\stop-lab.ps1

# Start the cluster
.\scripts\start-lab.ps1
```

### Automating Stop/Start

You can schedule these using Windows Task Scheduler or Azure Automation:

**Windows Task Scheduler**:
```powershell
# Create a scheduled task to stop the cluster at 6 PM daily
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\Users\Jamon\Documents\GitHub\AKS\scripts\stop-lab.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "6:00PM"
Register-ScheduledTask -TaskName "AKS-Lab-Stop" -Action $action -Trigger $trigger -Description "Stop AKS lab cluster"

# Create a scheduled task to start the cluster at 8 AM daily (weekdays only)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\Users\Jamon\Documents\GitHub\AKS\scripts\start-lab.ps1"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At "8:00AM"
Register-ScheduledTask -TaskName "AKS-Lab-Start" -Action $action -Trigger $trigger -Description "Start AKS lab cluster"
```

> **Note**: When the cluster is stopped, `kubectl` commands will fail. Start the cluster before running any lab exercises.

---

## Cost-Saving Tips

### 1. Use Dev Environment Defaults
The `environments/dev.tfvars` disables all optional toggles. Only enable toggles you are actively using for a lab exercise.

```powershell
# Deploy with dev defaults
.\scripts\deploy.ps1 -Environment dev
```

### 2. Minimize Node Count
Keep `system_node_pool_min = 1` and `user_node_pool_min = 1`. The Cluster Autoscaler will add nodes only when needed.

### 3. Cap Log Analytics Ingestion
Set a daily ingestion cap to prevent runaway log costs:

```hcl
# In the management landing zone
log_analytics_daily_quota_gb = 1  # Cap at 1 GB/day (~$2.76/day max)
```

### 4. Avoid Azure Firewall
Azure Firewall Basic costs ~$900/month. Use it only when specifically studying firewall rules. For lab purposes, NAT gateway or default outbound access is sufficient.

### 5. Clean Up Test Resources
After each lab day, remove workloads that generate unnecessary cost:

```powershell
# Remove stress test pods
kubectl delete -f k8s/apps/stress-cpu.yaml --ignore-not-found
kubectl delete -f k8s/apps/stress-memory.yaml --ignore-not-found

# Remove chaos experiments
kubectl delete -f k8s/chaos/ --ignore-not-found
```

### 6. Monitor Costs Regularly

```powershell
# Run the cost check script weekly
.\scripts\cost-check.ps1
```

Also set up the budget alert to notify you:
```hcl
budget_amount = 100  # Alert at $100
alert_email   = "your-email@example.com"
```

### 7. Use Burstable VM Sizes
The default `Standard_B2s` VMs are burstable, meaning they accumulate CPU credits during idle periods and burst above baseline during load. This is ideal for lab workloads with intermittent usage patterns.

---

## Teardown Checklist

When you are finished with the lab or want to reset:

### Quick Teardown (Workloads Only)
```powershell
.\scripts\cleanup-workloads.ps1
```

### Full Teardown (All Azure Resources)
```powershell
# 1. Destroy all infrastructure
.\scripts\destroy.ps1 -Environment dev

# 2. Verify resource groups are deleted
az group list --query "[?tags.project=='akslab']" -o table

# 3. Check for orphaned resources not tagged
az resource list -o table | Select-String "akslab"

# 4. Remove the Terraform state backend (optional - only if fully done)
az group delete --name rg-terraform-state --yes

# 5. Clean up local kubeconfig context
kubectl config delete-context aks-akslab-dev
kubectl config delete-cluster aks-akslab-dev
kubectl config delete-user clusterUser_rg-spoke-aks-networking-dev_aks-akslab-dev
```

### Post-Teardown Verification

| Check | Command | Expected |
|-------|---------|----------|
| No resource groups | `az group list --query "[?tags.project=='akslab']" -o table` | Empty |
| No orphaned resources | `az resource list --tag project=akslab -o table` | Empty |
| No running costs | Azure Portal → Cost Management → Cost analysis | $0 from teardown date |
| Kubeconfig clean | `kubectl config get-contexts` | No akslab contexts |

> **Important**: Azure charges may continue for 1–2 days after resource deletion due to billing cycle lag. Verify in Cost Management after 48 hours.
