# -----------------------------------------------------------------------------
# Outputs: monitoring/log-analytics
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_id" {
  description = "The workspace ID (GUID) of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "primary_shared_key" {
  description = "The primary shared key of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}
