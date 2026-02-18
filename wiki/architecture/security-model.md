<div align="center">

# 🔐 Security Model

**Defense-in-depth across network, cluster, identity, policy, and runtime controls**

[![Zero Trust](https://img.shields.io/badge/Approach-Zero_Trust-E34F26?style=flat-square)](#)
[![Calico](https://img.shields.io/badge/Network_Policy-Calico-FF6600?style=flat-square)](#)
[![Key Vault](https://img.shields.io/badge/Secrets-Azure_Key_Vault-0078D4?style=flat-square&logo=microsoftazure)](#)

---

</div>

## 🏠 Control Layers

1. Network perimeter: NSGs per subnet, optional Azure Firewall
2. Cluster network: Calico network policies
3. Pod security: Pod Security Admission labels
4. Secrets: Key Vault + CSI Secrets Store
5. Governance: Azure Policy assignments
6. Identity: managed identities + workload federation
7. Runtime: optional Defender for Containers

---

## 🌐 Layer 1: Network Perimeter

Subnets protected by NSGs:
- `snet-aks-system` -> `nsg-aks-system-{env}`
- `snet-aks-user` -> `nsg-aks-user-{env}`
- `snet-ingress` -> `nsg-ingress-{env}`
- `snet-private-endpoints` -> `nsg-private-endpoints-{env}`

Current notable inbound allows:
- System/user NSGs: `80`, `443`, and NodePort range `30000-32767` from Internet
- Ingress NSG: `80` and `443` from Internet
- Private endpoint NSG: `1433` and `443` from AKS subnet ranges

Firewall behavior:
- `enable_firewall = true` deploys firewall resources
- Internet egress is only forced through firewall when `route_internet_via_firewall = true`

---

## 🔗 Layer 2: Cluster Network (Calico Policies)

Network policies in `k8s/security/network-policies.yaml` include:

| Namespace | Key Policies |
|-----------|--------------|
| `lab-apps` | `default-deny-all`, `allow-dns-egress`, `allow-ingress-controller`, `allow-db-egress` |
| `lab-monitoring` | `default-deny-all`, `allow-dns-egress`, `allow-monitoring-egress` |
| `lab-ingress` | `default-deny-all`, `allow-dns-egress`, `allow-ingress-to-backends`, `allow-external-ingress` |
| `lab-security` | `default-deny-all`, `allow-dns-egress` |

---

## 🛡 Layer 3: Pod Security Admission

Configured in `k8s/security/pod-security-admission.yaml`:

| Namespace | enforce | audit | warn |
|-----------|---------|-------|------|
| `lab-apps` | `restricted` | `restricted` | `restricted` |
| `lab-monitoring` | `baseline` | `baseline` | `restricted` |

Note:
- PSA labels are explicitly set for `lab-apps` and `lab-monitoring` in current manifests.

---

## 🔑 Layer 4: Secrets Management

Security landing zone provisions:
- RBAC-enabled Key Vault
- CSI Secrets Store driver + Azure provider
- Sample secret: `sample-secret`

Key Vault access:
- AKS kubelet identity: `Key Vault Secrets User`
- Workload identity principal: `Key Vault Secrets User` (passed from root module)
- Current deployer: `Key Vault Administrator`

---

## 📜 Layer 5: Governance (Azure Policy)

Policies assigned at AKS scope:
- Built-in pod security baseline initiative (`Audit`)
- Custom: pods must have resource limits (`Audit` assignment)
- Custom: container images must match project ACR regex (`Audit` assignment)

---

## 🪡 Layer 6: Identity

Identity landing zone creates:
- Workload user-assigned identity + federated credential
- Metrics app user-assigned identity + federated credential
- Metrics storage account + RBAC assignments

Current root inputs:
- Workload namespace/service account: `lab-apps` / `learning-hub-sa`
- Metrics namespace/service account: `monitoring` / `metrics-app-sa`

---

## 🛰 Layer 7: Runtime Protection

Optional:
- `enable_defender = true` enables Defender for Containers pricing tier

---

## ✅ Validation Checks

```powershell
# Network policies
kubectl get networkpolicies -A

# PSA labels
kubectl get ns lab-apps --show-labels
kubectl get ns lab-monitoring --show-labels

# Key Vault outputs from Terraform
terraform output key_vault_name
terraform output key_vault_uri

# Policy assignments on AKS
$clusterId = az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query id -o tsv
az policy assignment list --scope $clusterId -o table
```

---

<div align="center">

**[⬆ Back to Architecture Overview](overview.md)** · **[Wiki Home](../README.md)**

</div>
