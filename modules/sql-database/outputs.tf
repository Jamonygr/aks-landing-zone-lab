# -----------------------------------------------------------------------------
# Outputs: sql-database
# -----------------------------------------------------------------------------

output "server_id" {
  description = "Resource ID of the SQL Server."
  value       = azurerm_mssql_server.this.id
}

output "server_fqdn" {
  description = "FQDN of the SQL Server."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_name" {
  description = "Name of the SQL Database."
  value       = azurerm_mssql_database.this.name
}

output "database_id" {
  description = "Resource ID of the SQL Database."
  value       = azurerm_mssql_database.this.id
}

output "admin_password" {
  description = "SQL admin password (sensitive)."
  value       = random_password.sql_admin.result
  sensitive   = true
}

output "connection_string" {
  description = "ADO.NET connection string (sensitive)."
  value       = "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.this.name};User ID=${var.admin_username};Password=${random_password.sql_admin.result};Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
  sensitive   = true
}

output "private_endpoint_ip" {
  description = "Private IP address of the SQL private endpoint."
  value       = module.sql_private_endpoint.private_ip_address
}
