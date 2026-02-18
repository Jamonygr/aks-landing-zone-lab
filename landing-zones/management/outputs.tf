#--------------------------------------------------------------
# AKS Landing Zone - Management Module Outputs
#--------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "grafana_endpoint" {
  description = "Endpoint URL for the Managed Grafana instance (empty if not deployed)"
  value       = try(azurerm_dashboard_grafana.main[0].endpoint, "")
}

output "action_group_id" {
  description = "Resource ID of the monitoring action group"
  value       = azurerm_monitor_action_group.aks_alerts.id
}

output "prometheus_workspace_id" {
  description = "Resource ID of the Managed Prometheus workspace (empty if not deployed)"
  value       = try(azurerm_monitor_workspace.prometheus[0].id, "")
}
