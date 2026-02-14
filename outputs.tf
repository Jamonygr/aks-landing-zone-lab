# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Outputs - Cluster Info, Endpoints, Kubeconfig                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

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

# ─── Monitoring ───────────────────────────────────────────────────────────────

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID"
  value       = module.management.log_analytics_workspace_id
}

output "grafana_endpoint" {
  description = "Azure Managed Grafana endpoint (if enabled)"
  value       = module.management.grafana_endpoint
}
