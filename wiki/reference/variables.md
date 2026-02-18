<div align="center">
  <img src="../images/wiki-reference.svg" alt="Reference" width="900"/>
</div>

<div align="center">

[![Variables](https://img.shields.io/badge/Variables-28-blue?style=for-the-badge)](.)
[![Validated](https://img.shields.io/badge/Validations-6-green?style=for-the-badge)](.)
[![Source](https://img.shields.io/badge/Source-variables.tf-orange?style=for-the-badge)](.)

</div>

# 📋 Variables Reference

All root input variables from `variables.tf`.

---

## 🌐 General

| Variable | Type | Default | Notes |
|----------|------|---------|-------|
| `environment` | `string` | `"dev"` | Allowed: `dev`, `lab`, `prod`, `staging` |
| `location` | `string` | `"eastus"` | Azure region for primary resources |
| `project_name` | `string` | `"akslab"` | Naming prefix input |
| `owner` | `string` | `"Jamon"` | Tag value for ownership/cost tracking |

---

## 🌍 Networking

| Variable | Type | Default | Notes |
|----------|------|---------|-------|
| `hub_vnet_cidr` | `string` | `"10.0.0.0/16"` | Hub address space |
| `spoke_aks_vnet_cidr` | `string` | `"10.1.0.0/16"` | Spoke address space |

---

## 🔀 Feature Toggles

| Variable | Type | Default | Notes |
|----------|------|---------|-------|
| `enable_firewall` | `bool` | `false` | Deploy Azure Firewall Basic in hub |
| `route_internet_via_firewall` | `bool` | `false` | Use firewall for `0.0.0.0/0` only when firewall is enabled |
| `enable_managed_prometheus` | `bool` | `false` | Deploy Azure Managed Prometheus |
| `enable_managed_grafana` | `bool` | `false` | Requires `enable_managed_prometheus = true` |
| `enable_defender` | `bool` | `false` | Defender for Containers pricing tier |
| `enable_dns_zone` | `bool` | `false` | Enables DNS zone + ingress A records |
| `enable_cluster_alerts` | `bool` | `true` | AKS diagnostics and alert rules |
| `enable_keda` | `bool` | `false` | Defined in root vars; not wired to Terraform resources yet |
| `enable_azure_files` | `bool` | `false` | Defined in root vars; not wired to Terraform resources yet |
| `enable_app_insights` | `bool` | `false` | Defined in root vars; not wired to Terraform resources yet |
| `data_location` | `string` | `""` | Optional SQL region override |
| `enable_sql_database` | `bool` | `false` | Enables optional data landing zone |

---

## ☸️ AKS

| Variable | Type | Default | Notes |
|----------|------|---------|-------|
| `kubernetes_version` | `string` | `"1.32"` | AKS version input |
| `system_node_pool_vm_size` | `string` | `"Standard_B2s"` | System node pool VM size |
| `user_node_pool_vm_size` | `string` | `"Standard_B2s"` | User node pool VM size |
| `system_node_pool_min` | `number` | `1` | Autoscaler minimum |
| `system_node_pool_max` | `number` | `2` | Must be >= `system_node_pool_min` |
| `user_node_pool_min` | `number` | `1` | Autoscaler minimum |
| `user_node_pool_max` | `number` | `3` | Must be >= `user_node_pool_min` |

---

## 🌐 DNS

| Variable | Type | Default | Notes |
|----------|------|---------|-------|
| `dns_zone_name` | `string` | `""` | Required when `enable_dns_zone = true` |

---

## 💰 Alerts And Cost

| Variable | Type | Default | Notes |
|----------|------|---------|-------|
| `alert_email` | `string` | `"admin@example.com"` | Must match email format validation |
| `budget_amount` | `number` | `100` | Monthly budget threshold (USD) |

---

## ✅ Validation Rules

1. `environment` is restricted to `dev`, `lab`, `prod`, `staging`.
2. `enable_managed_grafana` requires `enable_managed_prometheus = true`.
3. `system_node_pool_max >= system_node_pool_min`.
4. `user_node_pool_max >= user_node_pool_min`.
5. `dns_zone_name` must be non-empty when DNS is enabled.
6. `alert_email` must be a valid email format.

---

## 📂 Environment Files

Current defaults are captured in:

- `environments/dev.tfvars`
- `environments/lab.tfvars`
- `environments/prod.tfvars`

Notable values:
- `lab` and `prod` enable DNS and SQL database.
- `prod` enables firewall and defender.
- `route_internet_via_firewall` is currently `false` in `prod`.

---

<div align="center">

**[&larr; Naming Conventions](naming-conventions.md)** &nbsp;&nbsp;|&nbsp;&nbsp; **[Wiki Home](../README.md)** &nbsp;&nbsp;|&nbsp;&nbsp; **[Outputs &rarr;](outputs.md)**

</div>
