<div align="center">
  <img src="../images/guide-troubleshooting.svg" alt="Troubleshooting Guide" width="900"/>
</div>

<div align="center">

[![Terraform](https://img.shields.io/badge/Terraform-Fixes-purple?style=for-the-badge&logo=terraform)](.)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Debug-blue?style=for-the-badge&logo=kubernetes)](.)
[![Azure CLI](https://img.shields.io/badge/Azure_CLI-Solutions-orange?style=for-the-badge)](.)

</div>

# \ud83d\udd27 Troubleshooting Guide

> **Quick fixes for common errors** — organized by category with symptoms, causes, and step-by-step resolutions.

---

## \u2601\ufe0f Terraform Issues

### State Lock Error

**Symptom**:
```
Error: Error locking state: Error acquiring the state lock
```

**Cause**: A previous `terraform apply` or `plan` was interrupted, leaving a lock on the state file in Azure Blob Storage.

**Resolution**:
```powershell
# Option 1: Force-unlock (use the lock ID from the error message)
terraform force-unlock <LOCK_ID>

# Option 2: Manually break the lease on the blob
az storage blob lease break `
  --blob-name terraform.tfstate `
  --container-name tfstate `
  --account-name stakslabtfstate
```

> **Warning**: Only force-unlock if you are certain no other operation is running.

### Terraform Init Fails (Backend)

**Symptom**:
```
Error: Failed to get existing workspaces: storage: service returned error: StatusCode=404
```

**Cause**: The state storage account or container doesn't exist.

**Resolution**:
```powershell
# Re-run the bootstrap script to create state backend
.\scripts\bootstrap.ps1
```

### Provider Version Conflicts

**Symptom**:
```
Error: Failed to query available provider packages
```

**Resolution**:
```powershell
# Delete the lock file and re-init
Remove-Item .terraform.lock.hcl
terraform init -upgrade
```

### Resource Already Exists

**Symptom**:
```
Error: A resource with the ID "/subscriptions/.../resourceGroups/rg-hub-networking-dev" already exists
```

**Cause**: Resource exists in Azure but not in Terraform state (often after a partial destroy or manual creation).

**Resolution**:
```powershell
# Import the existing resource into Terraform state
terraform import module.networking.azurerm_resource_group.hub /subscriptions/<sub-id>/resourceGroups/rg-hub-networking-dev

# Or destroy the resource manually first
az group delete --name rg-hub-networking-dev --yes --no-wait
```

---

## AKS Cluster Issues

### Cluster Not Starting / Provisioning State Failed

**Symptom**: Cluster shows `Failed` provisioning state or times out during creation.

**Resolution**:
```powershell
# Check cluster status
az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query provisioningState -o tsv

# Check for Azure region capacity issues
az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query powerState -o json

# If cluster is stuck, try reconciling
az aks update -g rg-spoke-aks-networking-dev -n aks-akslab-dev

# Check available VM sizes in your region
az vm list-skus --location eastus --size Standard_B2s --output table
```

**Common causes**:
- Regional VM quota exceeded → Request quota increase in the portal
- Subnet address space exhausted → Expand the subnet CIDR
- Invalid Kubernetes version → Check supported versions: `az aks get-versions --location eastus -o table`

### Cannot Get Credentials / kubectl Not Connecting

**Symptom**:
```
Unable to connect to the server: dial tcp: lookup ... no such host
```

**Resolution**:
```powershell
# Re-fetch credentials
az aks get-credentials --resource-group rg-spoke-aks-networking-dev --name aks-akslab-dev --overwrite-existing

# Verify current context
kubectl config current-context

# Test connectivity
kubectl cluster-info

# If cluster is stopped, start it first
.\scripts\start-lab.ps1
```

### Cluster Stopped and Won't Start

**Symptom**: `az aks start` returns an error or times out.

**Resolution**:
```powershell
# Check current power state
az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query powerState.code -o tsv

# Force start
az aks start -g rg-spoke-aks-networking-dev -n aks-akslab-dev --no-wait

# Watch the operation
az aks wait -g rg-spoke-aks-networking-dev -n aks-akslab-dev --updated --timeout 600
```

---

## Pod Issues

### Pods Stuck in Pending

**Symptom**: `kubectl get pods` shows `Pending` status indefinitely.

**Diagnosis**:
```powershell
# Describe the pod for events
kubectl describe pod <pod-name> -n <namespace>

# Common Events:
# "FailedScheduling" - No nodes with enough resources
# "Unschedulable" - Node affinity/taint issues
```

**Common causes and fixes**:

| Cause | Fix |
|-------|-----|
| Insufficient CPU/memory | Reduce pod resource requests or scale up node pool |
| Node taints preventing scheduling | Add tolerations to pod spec or use user node pool |
| PVC not bound | Check StorageClass and PV availability |
| Resource quota exceeded | Check: `kubectl describe quota -n <namespace>` |

```powershell
# Check node resources
kubectl describe nodes | Select-String -Pattern "Allocated|Capacity|cpu|memory" -Context 0,2

# Check resource quota usage
kubectl describe resourcequota -n lab-apps
```

### Pods in CrashLoopBackOff

**Symptom**: Pod restarts repeatedly with `CrashLoopBackOff` status.

**Diagnosis**:
```powershell
# Check pod logs (current crash)
kubectl logs <pod-name> -n <namespace>

# Check previous crash logs
kubectl logs <pod-name> -n <namespace> --previous

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>
```

**Common causes**:

| Cause | Resolution |
|-------|-----------|
| Application error | Fix the application code; check logs for stack trace |
| Missing ConfigMap/Secret | Verify referenced ConfigMaps and Secrets exist |
| Liveness probe failing | Adjust `initialDelaySeconds` or check probe endpoint |
| OOMKilled | Increase memory limits or optimize application memory usage |
| Missing dependencies | Ensure init containers complete and dependent services are running |

### Pods in ImagePullBackOff

**Symptom**: Pod shows `ImagePullBackOff` or `ErrImagePull`.

**Diagnosis**:
```powershell
kubectl describe pod <pod-name> -n <namespace> | Select-String "Events:" -Context 0,10
```

**Resolution**:
```powershell
# Verify ACR attachment
az aks check-acr --resource-group rg-spoke-aks-networking-dev --name aks-akslab-dev --acr $(terraform output -raw acr_login_server)

# Verify image exists in ACR
az acr repository list --name $(terraform output -raw acr_login_server | ForEach-Object { $_.Split('.')[0] }) -o table

# For public images, verify image name and tag
kubectl run test --image=nginx:alpine --restart=Never --dry-run=client -o yaml

# Re-attach ACR if needed
az aks update -g rg-spoke-aks-networking-dev -n aks-akslab-dev --attach-acr <acr-name>
```

### OOMKilled Containers

**Symptom**: Container terminated with reason `OOMKilled`.

```powershell
# Find OOMKilled pods
kubectl get pods -A -o json | ConvertFrom-Json | Select-Object -ExpandProperty items | Where-Object { $_.status.containerStatuses.lastState.terminated.reason -eq "OOMKilled" }

# Check memory limits
kubectl describe pod <pod-name> -n <namespace> | Select-String -Pattern "Limits|Requests|memory" -Context 0,1
```

**Resolution**: Increase `resources.limits.memory` in the pod spec. If the application genuinely requires more memory, consider a larger VM size for the node pool.

---

## Network Connectivity Issues

### Pod Cannot Reach External Services

**Diagnosis**:
```powershell
# Test from within a pod
kubectl exec -it deploy/dns-test -n lab-apps -- nslookup google.com
kubectl exec -it deploy/dns-test -n lab-apps -- wget -qO- --timeout=5 https://google.com

# Check network policy
kubectl get networkpolicies -n lab-apps
```

**Common causes**:
- **Default-deny egress policy** blocking outbound traffic → Add an egress allow rule
- **NSG blocking outbound** → Check NSG rules on the subnet
- **DNS resolution failing** → Check CoreDNS pods: `kubectl get pods -n kube-system -l k8s-app=kube-dns`

### Service Not Reachable from Another Namespace

**Cause**: Default-deny network policies block cross-namespace traffic.

**Resolution**: Add a NetworkPolicy allowing ingress from the source namespace.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-monitoring
  namespace: lab-apps
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              purpose: monitoring
```

### Ingress controller not getting External IP

**Symptom**: `kubectl get svc -n ingress-nginx` shows `<pending>` for EXTERNAL-IP.

**Resolution**:
```powershell
# Check Load Balancer events
kubectl describe svc ingress-nginx-controller -n ingress-nginx

# Common issue: Public IP resource not found
# Verify the public IP exists
az network public-ip list -g rg-spoke-aks-networking-dev -o table

# Check for quota issues
az network lb list -g MC_rg-spoke-aks-networking-dev_aks-akslab-dev_eastus -o table
```

---

## ACR Pull Errors

### AKS Cannot Pull from ACR

**Symptom**: `Failed to pull image` errors referencing your ACR.

```powershell
# Verify ACR role assignment
az role assignment list --scope $(az acr show -n <acr-name> --query id -o tsv) -o table

# Run connectivity check
az aks check-acr -g rg-spoke-aks-networking-dev -n aks-akslab-dev --acr <acr-name>.azurecr.io

# Manually attach if missing
az aks update -g rg-spoke-aks-networking-dev -n aks-akslab-dev --attach-acr <acr-name>
```

---

## Certificate / TLS Issues

### Ingress TLS Not Working

**Symptom**: HTTPS connections fail or show invalid certificate.

**Diagnosis**:
```powershell
# Check certificate secret
kubectl get secrets -n lab-apps -l app=hello-web

# Check ingress TLS configuration
kubectl describe ingress hello-web -n lab-apps

# Test with curl (skip verify for self-signed)
curl -vk https://$ingressIP -H "Host: hello-web.local"
```

**Resolution**:
- For lab: use HTTP only (TLS optional in lab environment)
- For TLS: install cert-manager and configure ClusterIssuer:
  ```powershell
  helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
  ```

---

## Cost Overruns

### Unexpected High Costs

**Diagnosis**:
```powershell
# Check current costs
.\scripts\cost-check.ps1

# List all resources with cost tags
az resource list --tag project=akslab -o table

# Check for unintended resources
az resource list --query "[?tags.project==null]" -o table
```

**Common causes**:

| Cause | Impact | Fix |
|-------|--------|-----|
| Firewall left on | +$900/mo | Set `enable_firewall = false` |
| Cluster running 24/7 | +$40/mo vs stop/start | Use `.\scripts\stop-lab.ps1` after hours |
| Log Analytics high ingest | +$2.76/GB | Set `log_analytics_daily_quota_gb` |
| Defender enabled | +$7/node/mo | Set `enable_defender = false` |
| Leftover resources after destroy | Varies | Check all resource groups manually |

```powershell
# Stop cluster to save costs
.\scripts\stop-lab.ps1

# Verify no orphaned resources
az group list --query "[?tags.project=='akslab']" -o table
```

### Budget Alert Not Firing

**Resolution**:
```powershell
# Verify budget exists
az consumption budget list --subscription $(az account show --query id -o tsv) -o table

# Check alert_email is configured correctly
grep "alert_email" environments/dev.tfvars
```

---

## Quick Diagnostic Commands

```powershell
# Cluster health overview
kubectl get nodes -o wide
kubectl get pods -A --field-selector=status.phase!=Running
kubectl get events -A --sort-by='.lastTimestamp' | Select-Object -Last 20

# Resource usage
kubectl top nodes
kubectl top pods -n lab-apps

# Network diagnostics
kubectl get networkpolicies -A
kubectl get svc -A

# Storage diagnostics
kubectl get pvc -A
kubectl get pv

# Terraform diagnostics
terraform state list
terraform plan -var-file="environments/dev.tfvars"
```
