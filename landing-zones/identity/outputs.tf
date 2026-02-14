#--------------------------------------------------------------
# AKS Landing Zone - Identity Module Outputs
#--------------------------------------------------------------

output "workload_identity_client_id" {
  description = "Client ID of the workload identity managed identity"
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID of the workload identity managed identity"
  value       = azurerm_user_assigned_identity.workload.principal_id
}

output "metrics_app_identity_client_id" {
  description = "Client ID of the metrics app managed identity"
  value       = azurerm_user_assigned_identity.metrics_app.client_id
}

output "metrics_app_identity_principal_id" {
  description = "Principal ID of the metrics app managed identity"
  value       = azurerm_user_assigned_identity.metrics_app.principal_id
}

output "metrics_storage_account_name" {
  description = "Name of the storage account for metrics data"
  value       = azurerm_storage_account.metrics.name
}

output "metrics_storage_container_name" {
  description = "Name of the blob container for metrics data"
  value       = azurerm_storage_container.metrics_data.name
}
