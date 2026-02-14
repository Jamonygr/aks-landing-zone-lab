# -----------------------------------------------------------------------------
# Outputs: networking/subnet
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the subnet."
  value       = azurerm_subnet.this.id
}

output "name" {
  description = "The name of the subnet."
  value       = azurerm_subnet.this.name
}
