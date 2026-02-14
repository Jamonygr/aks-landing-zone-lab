# -----------------------------------------------------------------------------
# Outputs: monitoring/nsg-flow-logs
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the flow log resource."
  value       = azurerm_network_watcher_flow_log.this.id
}
