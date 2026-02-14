# -----------------------------------------------------------------------------
# Outputs: monitoring/action-group
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the action group."
  value       = azurerm_monitor_action_group.this.id
}
