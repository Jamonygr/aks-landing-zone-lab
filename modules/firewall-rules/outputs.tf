# -----------------------------------------------------------------------------
# Outputs: firewall-rules
# -----------------------------------------------------------------------------

output "network_rule_collection_id" {
  description = "The ID of the network rule collection."
  value       = azurerm_firewall_network_rule_collection.this.id
}

output "app_rule_collection_id" {
  description = "The ID of the application rule collection."
  value       = azurerm_firewall_application_rule_collection.this.id
}
