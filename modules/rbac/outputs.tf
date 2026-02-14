# -----------------------------------------------------------------------------
# Outputs: rbac
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the role assignment."
  value       = azurerm_role_assignment.this.id
}
