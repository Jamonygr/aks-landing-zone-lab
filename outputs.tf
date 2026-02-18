# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Outputs - Cluster Info, Endpoints, Kubeconfig                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

data "azurerm_client_config" "current" {}

# ─── Cluster ──────────────────────────────────────────────────────────────────

output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks_platform.cluster_name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks_platform.cluster_fqdn
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig"
  value       = "az aks get-credentials --resource-group ${module.networking.spoke_resource_group_name} --name ${module.aks_platform.cluster_name}"
}

output "spoke_resource_group_name" {
  description = "Resource group name that contains AKS and spoke networking resources"
  value       = module.networking.spoke_resource_group_name
}

# ─── Networking ───────────────────────────────────────────────────────────────

output "hub_vnet_id" {
  description = "Hub VNet resource ID"
  value       = module.networking.hub_vnet_id
}

output "spoke_vnet_id" {
  description = "Spoke VNet resource ID"
  value       = module.networking.spoke_vnet_id
}

output "ingress_public_ip" {
  description = "Public IP of the NGINX ingress controller"
  value       = module.aks_platform.ingress_public_ip
}

# ─── ACR ──────────────────────────────────────────────────────────────────────

output "acr_login_server" {
  description = "ACR login server URL"
  value       = module.aks_platform.acr_login_server
}

output "workload_identity_client_id" {
  description = "Client ID of the workload managed identity used by lab applications"
  value       = module.identity.workload_identity_client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID of the workload managed identity used by lab applications"
  value       = module.identity.workload_identity_principal_id
}

# ─── Monitoring ───────────────────────────────────────────────────────────────

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID"
  value       = module.management.log_analytics_workspace_id
}

output "grafana_endpoint" {
  description = "Azure Managed Grafana endpoint (if enabled)"
  value       = module.management.grafana_endpoint
}

output "key_vault_name" {
  description = "Azure Key Vault name used for secrets sync"
  value       = module.security.key_vault_name
}

output "key_vault_uri" {
  description = "Azure Key Vault URI used for secrets sync"
  value       = module.security.key_vault_uri
}

output "tenant_id" {
  description = "Azure AD tenant ID for the active subscription context"
  value       = data.azurerm_client_config.current.tenant_id
}

# ─── Data ─────────────────────────────────────────────────────────────────────

output "sql_server_fqdn" {
  description = "Azure SQL Server FQDN (if enabled)"
  value       = var.enable_sql_database ? module.data[0].sql_server_fqdn : ""
}

output "sql_database_name" {
  description = "Azure SQL Database name (if enabled)"
  value       = var.enable_sql_database ? module.data[0].sql_database_name : ""
}


