#--------------------------------------------------------------
# AKS Landing Zone - Governance Module Outputs
#--------------------------------------------------------------

output "policy_assignment_ids" {
  description = "Map of policy assignment names to their resource IDs"
  value = {
    deny_pods_no_limits = azurerm_resource_policy_assignment.deny_pods_no_limits.id
    enforce_acr_images  = azurerm_resource_policy_assignment.enforce_acr_images.id
  }
}

output "policy_definition_ids" {
  description = "Map of custom policy definition names to their resource IDs"
  value = {
    deny_pods_no_limits = azurerm_policy_definition.deny_pods_no_limits.id
    enforce_acr_images  = azurerm_policy_definition.enforce_acr_images.id
  }
}

output "resource_graph_query_id" {
  description = "Resource Graph query resource ID (not created by this module)"
  value       = ""
}
