# -----------------------------------------------------------------------------
# Outputs: cost-management
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the consumption budget."
  value       = azurerm_consumption_budget_subscription.this.id
}
