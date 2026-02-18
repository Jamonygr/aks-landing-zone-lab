<div align="center">
  <img src="../images/guide-troubleshooting.svg" alt="Troubleshooting Guide" width="900"/>
</div>

<div align="center">

[![Terraform](https://img.shields.io/badge/Terraform-Fixes-purple?style=for-the-badge&logo=terraform)](.)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Debug-blue?style=for-the-badge&logo=kubernetes)](.)
[![Azure CLI](https://img.shields.io/badge/Azure_CLI-Checks-orange?style=for-the-badge)](.)

</div>

# 🔧 Troubleshooting Guide

Common fixes aligned to the current repo configuration.

---

## 1. Terraform State And Backend

State lock error:

```powershell
terraform force-unlock <LOCK_ID>
```

If you need to break blob lease manually, use the current backend key:

```powershell
az storage blob lease break `
  --blob-name aks-landing-zone-lab.tfstate `
  --container-name tfstate `
  --account-name stakslabtfstate
```

Backend 404 during `terraform init`:

```powershell
.\scripts\bootstrap.ps1
terraform init -reconfigure
```

---

## 2. AKS Access

Credentials refresh:

```powershell
az aks get-credentials --resource-group rg-spoke-aks-networking-dev --name aks-akslab-dev --overwrite-existing
kubectl cluster-info
```

If cluster is stopped:

```powershell
.\scripts\start-lab.ps1 -Environment dev
```

---

## 3. Pods Stuck Or Failing

Pending pods:

```powershell
kubectl describe pod <pod> -n <namespace>
kubectl describe nodes
kubectl describe resourcequota -n <namespace>
```

CrashLoopBackOff:

```powershell
kubectl logs <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --previous
kubectl describe pod <pod> -n <namespace>
```

ImagePullBackOff:

```powershell
$acr = terraform output -raw acr_login_server
az aks check-acr -g rg-spoke-aks-networking-dev -n aks-akslab-dev --acr $acr
```

---

## 4. Ingress External IP Pending

Ingress public IP is created in the AKS **node resource group**.

```powershell
$nodeRg = az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query nodeResourceGroup -o tsv
az network public-ip list -g $nodeRg -o table
kubectl describe svc ingress-nginx-controller -n ingress-nginx
```

---

## 5. Network And Policy Issues

Check network policies:

```powershell
kubectl get networkpolicies -A
```

Check spoke route behavior:

```powershell
az network route-table route list -g rg-spoke-aks-networking-dev --route-table-name rt-spoke-aks-dev -o table
```

Remember:
- Firewall does not automatically force internet egress unless `route_internet_via_firewall = true`.

---

## 6. Monitoring And Alerts

No log data:

```powershell
terraform output log_analytics_workspace_id
az monitor diagnostic-settings list --resource $(az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query id -o tsv)
```

No alert emails:

```powershell
Select-String -Path environments/dev.tfvars -Pattern "alert_email|enable_cluster_alerts|budget_amount"
```

---

## 7. Cost Overruns

```powershell
.\scripts\cost-check.ps1 -Environment dev
.\scripts\stop-lab.ps1 -Environment dev
```

Key high-cost toggles:
- `enable_firewall`
- `enable_defender`

---

## 8. Quick Health Commands

```powershell
kubectl get nodes -o wide
kubectl get pods -A
kubectl get events -A --sort-by='.lastTimestamp' | Select-Object -Last 30
terraform plan -var-file="environments/dev.tfvars"
```

---

<div align="center">

**[⬅ Wiki Home](../README.md)** · **[Monitoring Guide](monitoring-guide.md)**

</div>
