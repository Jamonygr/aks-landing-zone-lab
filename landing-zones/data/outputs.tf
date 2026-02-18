#--------------------------------------------------------------
# AKS Landing Zone - Data Module Outputs
#--------------------------------------------------------------

output "sql_server_fqdn" {
  description = "FQDN of the Azure SQL Server (empty if not deployed)"
  value       = var.enable_sql_database ? module.sql_database[0].server_fqdn : ""
}

output "sql_database_name" {
  description = "Name of the SQL Database (empty if not deployed)"
  value       = var.enable_sql_database ? module.sql_database[0].database_name : ""
}

output "data_resource_group_name" {
  description = "Name of the data resource group"
  value       = azurerm_resource_group.data.name
}
