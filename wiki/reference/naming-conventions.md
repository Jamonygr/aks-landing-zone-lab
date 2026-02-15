<div align="center">
  <img src="../images/wiki-reference.svg" alt="Reference" width="900"/>
</div>

<div align="center">

[![CAF](https://img.shields.io/badge/Standard-Cloud_Adoption_Framework-blue?style=for-the-badge)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
[![Pattern](https://img.shields.io/badge/Pattern-prefix--project--env-green?style=for-the-badge)](.)

</div>

# \ud83c\udff7\ufe0f Naming Conventions

All Azure resources in the AKS Landing Zone Lab follow a consistent naming convention based on Microsoft's [Cloud Adoption Framework naming guidance](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming).

---

## \ud83d\udcdd Convention Pattern

```
{resource-type-prefix}-{project-name}-{environment}-{qualifier}
```

| Component | Description | Example |
|-----------|------------|---------|
| Resource type prefix | Abbreviation per resource type (CAF standard) | `rg-`, `vnet-`, `aks-`, `kv-` |
| Project name | Project identifier | `akslab` |
| Environment | Deployment environment | `dev`, `lab`, `prod` |
| Qualifier | Optional sub-component | `hub`, `spoke`, `system` |

## ⚙️ Naming Variables

Set in `variables.tf` / `locals.tf`:

```hcl
variable "project_name" {
  default = "akslab"
}

variable "environment" {
  default = "dev"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}
```

---

## 📚 Resource Naming Reference

### 📦 Resource Groups

| Resource | Naming Pattern | Example (dev) |
|----------|---------------|---------------|
| Hub Networking | `rg-hub-networking-{env}` | `rg-hub-networking-dev` |
| Spoke AKS Networking | `rg-spoke-aks-networking-{env}` | `rg-spoke-aks-networking-dev` |
| Management | `rg-management-{env}` | `rg-management-dev` |
| Security | `rg-security-{env}` | `rg-security-dev` |
| Identity | `rg-identity-{env}` | `rg-identity-dev` |
| Terraform State | `rg-terraform-state` | `rg-terraform-state` |

### 🌐 Networking

| Resource | Naming Pattern | Example (dev) |
|----------|---------------|---------------|
| Hub VNet | `vnet-hub-{env}` | `vnet-hub-dev` |
| Spoke VNet | `vnet-spoke-aks-{env}` | `vnet-spoke-aks-dev` |
| Management Subnet | `snet-management` | `snet-management` |
| Shared Services Subnet | `snet-shared-services` | `snet-shared-services` |
| Firewall Subnet | `AzureFirewallSubnet` | `AzureFirewallSubnet` (Azure-required) |
| AKS System Subnet | `snet-aks-system` | `snet-aks-system` |
| AKS User Subnet | `snet-aks-user` | `snet-aks-user` |
| Ingress Subnet | `snet-ingress` | `snet-ingress` |
| NSG (System) | `nsg-aks-system-{env}` | `nsg-aks-system-dev` |
| NSG (User) | `nsg-aks-user-{env}` | `nsg-aks-user-dev` |
| NSG (Ingress) | `nsg-ingress-{env}` | `nsg-ingress-dev` |
| Route Table | `rt-spoke-{env}` | `rt-spoke-dev` |

### ☁️ Compute

| Resource | Naming Pattern | Example (dev) |
|----------|---------------|---------------|
| AKS Cluster | `aks-{project}-{env}` | `aks-akslab-dev` |
| System Node Pool | `system` | `system` (Kubernetes naming rules) |
| User Node Pool | `user` | `user` |
| Container Registry | `acr{project}{env}` | `acrakslab dev` (no hyphens allowed) |
| Public IP (Ingress) | `pip-ingress-{env}` | `pip-ingress-dev` |

### 📊 Monitoring

| Resource | Naming Pattern | Example (dev) |
|----------|---------------|---------------|
| Log Analytics Workspace | `law-aks-{env}` | `law-aks-dev` |
| Action Group | `ag-aks-{env}` | `ag-aks-dev` |
| Diagnostic Setting | `diag-{resource}-{env}` | `diag-aks-management-dev` |
| Alert Rule | `alert-{condition}-{env}` | `alert-node-cpu-dev` |
| Budget | `budget-{project}-{env}` | `budget-akslab-dev` |

### 🔒 Security

| Resource | Naming Pattern | Example (dev) |
|----------|---------------|---------------|
| Key Vault | `kv-aks-{env}-{hash}` | `kv-aks-dev-a1b2c3` |
| Policy Assignment | `pol-{policy}-{env}` | `pol-pod-security-baseline-dev` |

### 🔑 Identity

| Resource | Naming Pattern | Example (dev) |
|----------|---------------|---------------|
| Workload Identity | `id-workload-{cluster}-{env}` | `id-workload-aks-akslab-dev-dev` |
| Metrics App Identity | `id-metrics-app-{cluster}-{env}` | `id-metrics-app-aks-akslab-dev-dev` |
| Federated Credential | `fic-{purpose}-{cluster}` | `fic-workload-aks-akslab-dev` |
| Storage Account | `stmetrics{env}{hash}` | `stmetricsdev1a2b3c` |

### 🔥 Firewall (Optional)

| Resource | Naming Pattern | Example (dev) |
|----------|---------------|---------------|
| Azure Firewall | `fw-{env}` | `fw-dev` |
| Firewall Public IP | `pip-fw-{env}` | `pip-fw-dev` |
| Network Rule Collection | `{name}-network-rules` | `aks-egress-network-rules` |
| Application Rule Collection | `{name}-app-rules` | `aks-egress-app-rules` |

---

## ☸️ Kubernetes Resource Naming

Kubernetes resources follow a separate naming convention within the cluster:

### Namespaces

| Namespace | Purpose |
|-----------|---------|
| `lab-apps` | Application workloads |
| `lab-monitoring` | Monitoring stack (Prometheus, exporters) |
| `lab-ingress` | Ingress controller components |
| `lab-security` | Security-related workloads |
| `ingress-nginx` | NGINX ingress controller (Helm default) |
| `chaos-testing` | Chaos Mesh components |
| `flux-system` | Flux v2 controllers |
| `kube-system` | Kubernetes system components |

### Workloads

| Workload | Naming Pattern | Namespace |
|----------|---------------|-----------|
| Deployments | `{app-name}` (lowercase, hyphenated) | `lab-apps` |
| Services | Same as deployment name | `lab-apps` |
| Ingress | Same as deployment name | `lab-apps` |
| HPA | `{app-name}-hpa` | `lab-apps` |
| Network Policies | `{action}-{description}` | Various |

---

## ⚠️ Special Naming Rules

| Resource Type | Rule | Reason |
|---|---|---|
| Storage Accounts | 3–24 chars, lowercase, no hyphens | Azure naming constraint |
| Container Registries | 5–50 chars, alphanumeric only | Azure naming constraint |
| Key Vaults | 3–24 chars, must be globally unique | Hash suffix ensures uniqueness |
| AKS Node Pools | 1–12 chars, lowercase alphanumeric | Kubernetes naming constraint |
| Firewall Subnet | Must be exactly `AzureFirewallSubnet` | Azure service requirement |

---

## ⚙️ Naming Module

The `modules/naming/` module generates all names using the project and environment variables:

```hcl
module "naming" {
  source       = "./modules/naming"
  project_name = var.project_name
  environment  = var.environment
  location     = var.location
}

# Usage: module.naming.names.aks_cluster => "aks-akslab-dev-eastus"
```

Available names from the module: `rg_hub`, `rg_spoke`, `rg_mgmt`, `vnet_hub`, `vnet_spoke`, `snet_fw`, `snet_system`, `snet_user`, `aks_cluster`, `acr`, `kv`, `law`, `fw`, `pip_fw`, `nsg_system`, `nsg_user`, `rt_spoke`, `st`, `ag`, `dns_zone`, `ingress`, `budget`.

---

## 🏷️ Tagging Convention

All resources receive a standard tag set defined in `locals.tf`:

| Tag | Value | Purpose |
|-----|-------|---------|
| `project` | `akslab` | Project identification |
| `environment` | `dev` / `lab` / `prod` | Environment identification |
| `owner` | `Jamon` | Cost tracking and contact |
| `managed_by` | `terraform` | IaC identification |
| `lab` | `aks-landing-zone` | Lab identification |
| `created` | ISO 8601 timestamp | Creation tracking |

---

<div align="center">

**[&larr; Modules](../modules/README.md)** &nbsp;&nbsp;|&nbsp;&nbsp; **[Wiki Home](../README.md)** &nbsp;&nbsp;|&nbsp;&nbsp; **[Variables &rarr;](variables.md)**

</div>
