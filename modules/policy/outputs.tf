# -----------------------------------------------------------------------------
# Outputs: policy
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the policy assignment."
  value       = azurerm_resource_policy_assignment.this.id
}
