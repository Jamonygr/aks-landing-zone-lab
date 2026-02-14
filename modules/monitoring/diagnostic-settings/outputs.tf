# -----------------------------------------------------------------------------
# Outputs: monitoring/diagnostic-settings
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the diagnostic setting."
  value       = azurerm_monitor_diagnostic_setting.this.id
}
