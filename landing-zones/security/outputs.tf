#--------------------------------------------------------------
# AKS Landing Zone - Security Module Outputs
#--------------------------------------------------------------

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "policy_assignment_id" {
  description = "Resource ID of the pod security baseline policy assignment"
  value       = azurerm_resource_policy_assignment.pod_security_baseline.id
}
