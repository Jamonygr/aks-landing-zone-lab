<div align="center">

# 🏛 Architecture Overview

**Enterprise AKS deployment following the Cloud Adoption Framework**

[![CAF](https://img.shields.io/badge/Cloud_Adoption_Framework-✓-0078D4?style=flat-square&logo=microsoftazure)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
[![AKS Accelerator](https://img.shields.io/badge/AKS_Landing_Zone_Accelerator-✓-326CE5?style=flat-square&logo=kubernetes)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator)

---

</div>

## 🧭 Design Philosophy

The architecture is organized around **landing zones** — purpose-built environments that provide specific capabilities:

```
                    ┌────────────────────────┐
                    │  Root Module (main.tf) │
                    └────────────┬───────────┘
                               │
          ┌───────────┬───────┼───────┬─────────┬────────┐
          ▼           ▼       ▼       ▼         ▼        ▼
   ┌──────────┐ ┌──────┐ ┌────┐ ┌────────┐ ┌──────┐ ┌───────┐
   │Networking│ │ AKS  │ │Mgmt│ │Security│ │ Gov  │ │  ID   │
   └────┬─────┘ └──┬───┘ └────┘ └────────┘ └──────┘ └───────┘
        │          │
        └─────────▶│ (Networking feeds into AKS Platform)
                   │
        AKS Platform feeds into:
          ├──▶ Management
          ├──▶ Security
          ├──▶ Governance
          └──▶ Identity
```

Each landing zone is an independent Terraform module in `landing-zones/` that consumes reusable modules from `modules/`.

---

## 🧩 Key Components

<table>
<tr>
<td width="50%">

| Component | Technology |
|:----------|:-----------|
| **Network Topology** | Hub-Spoke VNets |
| **Compute** | AKS (Kubernetes 1.32) |
| **Pod Networking** | Azure CNI Overlay + Calico |
| **Ingress** | NGINX Ingress Controller |
| **Registry** | Azure Container Registry (Basic) |

</td>
<td width="50%">

| Component | Technology |
|:----------|:-----------|
| **Monitoring** | Log Analytics + Container Insights |
| **Security** | Key Vault + Azure Policy + PSA |
| **Identity** | Workload Identity Federation |
| **GitOps** | Flux v2 (CNCF Graduated) |
| **Cost Mgmt** | Azure Budget Alerts |

</td>
</tr>
</table>

> **💡 Tip:** Each component maps to a landing zone module. See the [Landing Zones](../landing-zones/README.md) page for resource-level details.

---

## 📖 Detailed Documentation

| | Topic | Page |
|:--|:------|:-----|
| 🌐 | Hub-spoke design, IP addressing, traffic flows, NSGs | [Network Topology](network-topology.md) |
| 🔐 | Identity, network policies, Key Vault, Defender, Azure Policy | [Security Model](security-model.md) |

---

## 🔗 Infrastructure Dependencies

```
  1. Networking ──▶ 2. AKS Platform ──┬──▶ 3. Management
                                     ├──▶ 4. Security
                                     ├──▶ 5. Governance
                                     └──▶ 6. Identity
```

Landing zones are deployed **in order**, with each zone depending on outputs from previous zones:

<table>
<tr>
<th align="center">#</th>
<th>Landing Zone</th>
<th>What It Creates</th>
<th>Depends On</th>
</tr>
<tr><td align="center"><b>1</b></td><td>🌐 <b>Networking</b></td><td>VNets, subnets, peerings, NSGs</td><td>—</td></tr>
<tr><td align="center"><b>2</b></td><td>⎈ <b>AKS Platform</b></td><td>Cluster, ACR, ingress</td><td>Networking (subnet IDs)</td></tr>
<tr><td align="center"><b>3</b></td><td>📈 <b>Management</b></td><td>Monitoring, alerts</td><td>AKS Platform (cluster ID)</td></tr>
<tr><td align="center"><b>4</b></td><td>🔐 <b>Security</b></td><td>Key Vault, policies</td><td>AKS Platform (cluster identity)</td></tr>
<tr><td align="center"><b>5</b></td><td>📋 <b>Governance</b></td><td>Custom Azure Policies</td><td>AKS Platform (cluster ID, ACR ID)</td></tr>
<tr><td align="center"><b>6</b></td><td>🪪 <b>Identity</b></td><td>Managed IDs, fed creds</td><td>AKS Platform (OIDC issuer URL)</td></tr>
</table>

> Steps 3–6 run **in parallel** after step 2 completes — Terraform resolves the dependency graph automatically.

---

## 🎯 Design Decisions

| # | Decision | Choice | Alternatives Considered | Rationale |
|:-:|:---------|:-------|:------------------------|:----------|
| 1 | API Server Access | **Public** | Private cluster | Simplified lab access; avoids need for jump box / VPN |
| 2 | Network Plugin | **Azure CNI Overlay** | Kubenet, Azure CNI | Overlay avoids IP exhaustion; compatible with Calico |
| 3 | Node VM Size | **Standard_B2s** | Standard_D2s_v3 | Burstable VMs are cost-effective for lab workloads |
| 4 | ACR SKU | **Basic** | Standard, Premium | Sufficient for lab; 10 GB included storage |
| 5 | Key Vault Auth | **RBAC** | Access Policies | RBAC is the recommended model; integrates with managed identities |
| 6 | Firewall | **Optional (OFF)** | Always-on | ~$900/mo is prohibitive for lab; NAT gateway suffices |
| 7 | State Backend | **Azure Blob Storage** | Local, S3, TFC | Native Azure integration; ~$0.01/mo for lab state |
| 8 | Auto-upgrade | **Patch channel** | None, Stable, Rapid | Automatic security patches; manual minor version control |

---

<div align="center">

**[⬆ Back to Wiki Home](../README.md)**

</div>
