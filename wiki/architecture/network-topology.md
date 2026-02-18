<div align="center">

# 🌐 Network Topology

**Hub-spoke networking for AKS with optional firewall-controlled egress**

[![Hub-Spoke](https://img.shields.io/badge/Pattern-Hub--Spoke-0078D4?style=flat-square&logo=microsoftazure)](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
[![Azure CNI](https://img.shields.io/badge/Plugin-Azure_CNI_Overlay-326CE5?style=flat-square&logo=kubernetes)](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay)

---

</div>

## 🏗 Topology

```text
Hub VNet (10.0.0.0/16)
  - snet-management (10.0.0.0/24)
  - snet-shared-services (10.0.1.0/24)
  - AzureFirewallSubnet (10.0.2.0/24)
  - AzureFirewallManagementSubnet (10.0.3.0/24, optional)

Spoke VNet (10.1.0.0/16)
  - snet-aks-system (10.1.0.0/24)
  - snet-aks-user (10.1.1.0/24)
  - snet-ingress (10.1.2.0/24)
  - snet-private-endpoints (10.1.3.0/24)

Hub <-> Spoke peering (bidirectional)
```

---

## ☸️ AKS Networking Values

| Setting | Value |
|---------|-------|
| Network plugin | Azure (`network_plugin_mode = "overlay"`) |
| Network policy | Calico |
| Pod CIDR | `192.168.0.0/16` |
| Service CIDR | `172.16.0.0/16` |
| DNS Service IP | `172.16.0.10` |

---

## 🛡 NSG Coverage

Subnets with NSGs:
- `snet-aks-system` -> `nsg-aks-system-{env}`
- `snet-aks-user` -> `nsg-aks-user-{env}`
- `snet-ingress` -> `nsg-ingress-{env}`
- `snet-private-endpoints` -> `nsg-private-endpoints-{env}`

Notable inbound allows:
- System/user NSGs allow HTTP/HTTPS from VNet and Internet
- System/user NSGs allow NodePort range `30000-32767` from Internet (for public ingress LB path)
- Ingress NSG allows HTTP/HTTPS from Internet
- Private endpoint NSG allows SQL (`1433`) and HTTPS (`443`) from AKS system/user subnet ranges

---

## 🗺 Route Behavior

Route table: `rt-spoke-aks-{env}` is associated with AKS system and user subnets.

Routes:
- `to-hub`: hub CIDR route through firewall private IP (only when firewall enabled)
- `to-internet`: default route `0.0.0.0/0`
  - next hop `Internet` by default
  - next hop `VirtualAppliance` only when both:
    - `enable_firewall = true`
    - `route_internet_via_firewall = true`

This means firewall enablement alone does not force all internet egress.

---

## 🔍 Diagnostics

When a Log Analytics workspace ID is supplied, diagnostics are enabled for:
- Hub and spoke VNets
- AKS system NSG
- Firewall (when enabled)

Logged categories include:
- NSG events/rule counters
- Firewall network/application rules
- All metrics for VNets and firewall

---

## ✅ Quick Validation Commands

```powershell
# VNet peering status
az network vnet peering list -g rg-hub-networking-dev --vnet-name vnet-hub-dev -o table
az network vnet peering list -g rg-spoke-aks-networking-dev --vnet-name vnet-spoke-aks-dev -o table

# Spoke route table
az network route-table route list -g rg-spoke-aks-networking-dev --route-table-name rt-spoke-aks-dev -o table

# AKS network profile
az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query networkProfile -o json
```

---

<div align="center">

**[⬆ Back to Architecture Overview](overview.md)** · **[Wiki Home](../README.md)**

</div>
