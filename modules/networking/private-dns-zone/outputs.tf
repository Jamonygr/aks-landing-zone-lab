# -----------------------------------------------------------------------------
# Outputs: networking/private-dns-zone
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the private DNS zone."
  value       = azurerm_private_dns_zone.this.id
}

output "name" {
  description = "The name of the private DNS zone."
  value       = azurerm_private_dns_zone.this.name
}
