# -----------------------------------------------------------------------------
# Outputs: acr
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the container registry."
  value       = azurerm_container_registry.this.id
}

output "login_server" {
  description = "The login server URL of the container registry."
  value       = azurerm_container_registry.this.login_server
}

output "admin_username" {
  description = "The admin username of the container registry."
  value       = azurerm_container_registry.this.admin_username
}
