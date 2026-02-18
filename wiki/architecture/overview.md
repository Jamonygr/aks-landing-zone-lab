<div align="center">

# 🏛 Architecture Overview

**Enterprise AKS deployment aligned to CAF landing-zone principles**

[![CAF](https://img.shields.io/badge/Cloud_Adoption_Framework-✓-0078D4?style=flat-square&logo=microsoftazure)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
[![AKS Accelerator](https://img.shields.io/badge/AKS_Landing_Zone_Accelerator-✓-326CE5?style=flat-square&logo=kubernetes)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator)

---

</div>

## 🧭 Structure

The root module deploys **7 landing zones**:

```text
networking -> aks-platform
aks-platform -> management, security, governance, identity
networking + management + security + identity -> data (optional)
```

Core stack:
- Hub-spoke VNets
- AKS (`kubernetes_version` default `1.32`) with Azure CNI Overlay + Calico
- ACR + ingress-nginx
- Monitoring, security, governance, workload identity
- Optional SQL data zone with private connectivity

---

## 📦 Landing Zones

| # | Zone | What It Creates | Depends On |
|---|------|------------------|------------|
| 1 | Networking | Hub/spoke VNets, subnets, NSGs, routing, optional firewall | — |
| 2 | AKS Platform | AKS cluster, ACR, ingress, optional DNS zone | Networking + Management workspace |
| 3 | Management | Log Analytics, diagnostics, alerts, budget, optional Prometheus/Grafana | AKS Platform |
| 4 | Security | Pod-security policy assignment, Key Vault, CSI driver, optional Defender | AKS Platform |
| 5 | Governance | Custom Kubernetes policy definitions + assignments | AKS Platform |
| 6 | Identity | User-assigned identities + federated credentials + metrics storage access | AKS Platform |
| 7 | Data (optional) | SQL database with private endpoint, private DNS, Key Vault secret | Networking + Management + Security + Identity |

---

## 🔑 Baseline Network Values

| Network | CIDR |
|---------|------|
| Hub VNet | `10.0.0.0/16` |
| Spoke VNet | `10.1.0.0/16` |
| Pod CIDR | `192.168.0.0/16` |
| Service CIDR | `172.16.0.0/16` |
| DNS Service IP | `172.16.0.10` |

---

## 📖 Deep Dives

- [Network Topology](network-topology.md)
- [Security Model](security-model.md)

---

<div align="center">

**[⬆ Back to Wiki Home](../README.md)**

</div>
