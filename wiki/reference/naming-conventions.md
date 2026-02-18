<div align="center">
  <img src="../images/wiki-reference.svg" alt="Reference" width="900"/>
</div>

<div align="center">

[![CAF](https://img.shields.io/badge/Standard-Cloud_Adoption_Framework-blue?style=for-the-badge)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
[![Pattern](https://img.shields.io/badge/Pattern-project--env-green?style=for-the-badge)](.)

</div>

# 🏷️ Naming Conventions

Current naming patterns used by the Terraform configuration.

---

## 🧩 Root Naming Inputs

From `locals.tf`:

```hcl
name_prefix  = "${var.project_name}-${var.environment}"
cluster_name = "aks-${local.name_prefix}"
acr_name     = lower(replace("acr${var.project_name}${var.environment}", "-", ""))
dns_prefix   = "${var.project_name}-${var.environment}"
```

Examples (dev):
- `project_name = "akslab"`
- `environment = "dev"`
- cluster name: `aks-akslab-dev`
- ACR name: `acrakslabdev`

---

## 📦 Resource Groups

| Scope | Pattern | Example |
|-------|---------|---------|
| Hub networking | `rg-hub-networking-{env}` | `rg-hub-networking-dev` |
| Spoke networking | `rg-spoke-aks-networking-{env}` | `rg-spoke-aks-networking-dev` |
| Management | `rg-management-{env}` | `rg-management-dev` |
| Security | `rg-security-{env}` | `rg-security-dev` |
| Governance | `rg-governance-{env}` | `rg-governance-dev` |
| Identity | `rg-identity-{env}` | `rg-identity-dev` |
| Data | `rg-data-{env}` | `rg-data-dev` |
| Terraform state | `rg-terraform-state` | `rg-terraform-state` |

---

## 🌐 Networking

| Resource | Pattern | Example |
|----------|---------|---------|
| Hub VNet | `vnet-hub-{env}` | `vnet-hub-dev` |
| Spoke VNet | `vnet-spoke-aks-{env}` | `vnet-spoke-aks-dev` |
| System NSG | `nsg-aks-system-{env}` | `nsg-aks-system-dev` |
| User NSG | `nsg-aks-user-{env}` | `nsg-aks-user-dev` |
| Ingress NSG | `nsg-ingress-{env}` | `nsg-ingress-dev` |
| Private endpoint NSG | `nsg-private-endpoints-{env}` | `nsg-private-endpoints-dev` |
| Route table | `rt-spoke-aks-{env}` | `rt-spoke-aks-dev` |
| Hub firewall | `fw-hub-{env}` | `fw-hub-dev` |
| Firewall policy | `fwpol-hub-{env}` | `fwpol-hub-dev` |
| Firewall data plane PIP | `pip-fw-hub-{env}` | `pip-fw-hub-dev` |
| Firewall mgmt PIP | `pip-fw-mgmt-hub-{env}` | `pip-fw-mgmt-hub-dev` |

Fixed subnet names:
- `snet-management`
- `snet-shared-services`
- `AzureFirewallSubnet`
- `AzureFirewallManagementSubnet` (when firewall enabled)
- `snet-aks-system`
- `snet-aks-user`
- `snet-ingress`
- `snet-private-endpoints`

---

## ☸️ AKS And Platform

| Resource | Pattern | Example |
|----------|---------|---------|
| AKS cluster | `aks-{project}-{env}` | `aks-akslab-dev` |
| System pool | `system` | `system` |
| User pool | `user` | `user` |
| ACR | `acr{project}{env}` | `acrakslabdev` |
| Ingress public IP | `pip-ingress-{cluster_name}` | `pip-ingress-aks-akslab-dev` |
| DNS zone (optional) | `dns_zone_name` variable | `akslab-lab.example.com` |

---

## 🔐 Security And Governance

| Resource | Pattern | Example |
|----------|---------|---------|
| Pod security policy assignment | `pol-pod-security-baseline-{env}` | `pol-pod-security-baseline-dev` |
| Key Vault | `kv-aks-{env}-{hash}` | `kv-aks-dev-a1b2c3` |
| Governance assignment (limits) | `asgn-deny-no-limits-{env}` | `asgn-deny-no-limits-dev` |
| Governance assignment (ACR) | `asgn-enforce-acr-{env}` | `asgn-enforce-acr-dev` |

---

## 🪪 Identity And Data

| Resource | Pattern | Example |
|----------|---------|---------|
| Workload identity | `id-workload-{cluster}-{env}` | `id-workload-aks-akslab-dev-dev` |
| Metrics identity | `id-metrics-app-{cluster}-{env}` | `id-metrics-app-aks-akslab-dev-dev` |
| Workload federated credential | `fic-workload-{cluster}` | `fic-workload-aks-akslab-dev` |
| Metrics federated credential | `fic-metrics-app-{cluster}` | `fic-metrics-app-aks-akslab-dev` |
| Metrics storage account | `stmetrics{env}{hash}` | `stmetricsdev1a2b3c` |
| SQL server | `sql-{env}-{hash}` | `sql-dev-1a2b3c4d` |

---

## 🏷️ Standard Tags

From `locals.tf`:

| Tag | Source |
|-----|--------|
| `project` | `var.project_name` |
| `environment` | `var.environment` |
| `owner` | `var.owner` |
| `managed_by` | `"terraform"` |
| `lab` | `"aks-landing-zone"` |

---

## ⚠️ Azure Naming Constraints

| Resource | Constraint |
|----------|------------|
| Storage accounts | 3-24 chars, lowercase, no hyphens |
| ACR | 5-50 chars, lowercase alphanumeric |
| Key Vault | 3-24 chars, globally unique |
| AKS node pool names | 1-12 chars, lowercase alphanumeric |
| Firewall subnet name | Must be exactly `AzureFirewallSubnet` |

---

<div align="center">

**[&larr; Modules](../modules/README.md)** &nbsp;&nbsp;|&nbsp;&nbsp; **[Wiki Home](../README.md)** &nbsp;&nbsp;|&nbsp;&nbsp; **[Variables &rarr;](variables.md)**

</div>
