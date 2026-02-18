<div align="center">
  <img src="../images/wiki-reference.svg" alt="Reference" width="900"/>
</div>

<div align="center">

[![Outputs](https://img.shields.io/badge/Outputs-17-blue?style=for-the-badge)](.)
[![Categories](https://img.shields.io/badge/Categories-5-green?style=for-the-badge)](.)
[![Source](https://img.shields.io/badge/Source-outputs.tf-orange?style=for-the-badge)](.)

</div>

# 📤 Outputs Reference

All root outputs from `outputs.tf`.

---

## ☸️ Cluster

| Output | Description |
|--------|-------------|
| `cluster_name` | AKS cluster name |
| `cluster_fqdn` | AKS API server FQDN |
| `kubeconfig_command` | Ready-to-run `az aks get-credentials` command |
| `spoke_resource_group_name` | Spoke resource group containing AKS resources |

---

## 🌐 Networking

| Output | Description |
|--------|-------------|
| `hub_vnet_id` | Hub VNet resource ID |
| `spoke_vnet_id` | Spoke VNet resource ID |
| `ingress_public_ip` | Public IP assigned to ingress controller |

---

## 📦 Registry And Identity

| Output | Description |
|--------|-------------|
| `acr_login_server` | ACR login server URL |
| `workload_identity_client_id` | Client ID for workload managed identity |
| `workload_identity_principal_id` | Principal ID for workload managed identity |

---

## 📊 Monitoring And Security

| Output | Description |
|--------|-------------|
| `log_analytics_workspace_id` | Log Analytics workspace ID |
| `grafana_endpoint` | Managed Grafana endpoint (empty when disabled) |
| `key_vault_name` | Key Vault name |
| `key_vault_uri` | Key Vault URI |
| `tenant_id` | Tenant ID of current Azure context |

---

## 🗄 Data

| Output | Description |
|--------|-------------|
| `sql_server_fqdn` | SQL server FQDN (empty when SQL disabled) |
| `sql_database_name` | SQL database name (empty when SQL disabled) |

---

## 💻 Usage

```powershell
# List all outputs
terraform output

# Pull specific values
terraform output -raw cluster_name
terraform output -raw ingress_public_ip
terraform output -raw acr_login_server

# Run kubeconfig command from output
terraform output -raw kubeconfig_command | Invoke-Expression

# JSON for scripting
terraform output -json
```

---

## 🔗 Source Mapping

| Output | Source |
|--------|--------|
| `cluster_name`, `cluster_fqdn`, `ingress_public_ip`, `acr_login_server` | `module.aks_platform` |
| `spoke_resource_group_name`, `hub_vnet_id`, `spoke_vnet_id` | `module.networking` |
| `workload_identity_client_id`, `workload_identity_principal_id` | `module.identity` |
| `log_analytics_workspace_id`, `grafana_endpoint` | `module.management` |
| `key_vault_name`, `key_vault_uri` | `module.security` |
| `tenant_id` | `data.azurerm_client_config.current` |
| `sql_server_fqdn`, `sql_database_name` | `module.data[0]` when enabled |

---

<div align="center">

**[&larr; Variables](variables.md)** &nbsp;&nbsp;|&nbsp;&nbsp; **[Wiki Home](../README.md)** &nbsp;&nbsp;|&nbsp;&nbsp; **[Naming Conventions](naming-conventions.md)**

</div>
