# -----------------------------------------------------------------------------
# Outputs: firewall
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the Azure Firewall."
  value       = azurerm_firewall.this.id
}

output "private_ip" {
  description = "The private IP address of the firewall."
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "public_ip" {
  description = "The public IP address of the firewall."
  value       = azurerm_public_ip.fw.ip_address
}
