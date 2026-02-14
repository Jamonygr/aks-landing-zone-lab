# -----------------------------------------------------------------------------
# Outputs: networking/vnet
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "The name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "The address space of the virtual network."
  value       = azurerm_virtual_network.this.address_space
}
