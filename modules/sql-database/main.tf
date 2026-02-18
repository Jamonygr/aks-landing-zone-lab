# -----------------------------------------------------------------------------
# Module: sql-database
# Description: Azure SQL Server + Database (Basic SKU) with private endpoint
# Estimated cost: ~$5/mo (Basic 5 DTU)
# -----------------------------------------------------------------------------

resource "random_password" "sql_admin" {
  length           = 24
  special          = true
  override_special = "!@#$%^&*"
}

resource "azurerm_mssql_server" "this" {
  name                          = var.server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.admin_username
  administrator_login_password  = random_password.sql_admin.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = var.tags

  azuread_administrator {
    login_username = var.aad_admin_login
    object_id      = var.aad_admin_object_id
    tenant_id      = var.tenant_id
  }
}

resource "azurerm_mssql_database" "this" {
  name         = var.database_name
  server_id    = azurerm_mssql_server.this.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "Basic"
  tags         = var.tags

  short_term_retention_policy {
    retention_days = 7
  }
}

# Private DNS Zone for SQL
module "sql_dns_zone" {
  source = "../networking/private-dns-zone"

  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
  vnet_ids            = var.vnet_ids
  tags                = var.tags
}

# Private Endpoint for SQL Server
module "sql_private_endpoint" {
  source = "../private-endpoint"

  name                           = "pe-${var.server_name}"
  location                       = var.private_endpoint_location != "" ? var.private_endpoint_location : var.location
  resource_group_name            = var.resource_group_name
  subnet_id                      = var.subnet_id
  private_connection_resource_id = azurerm_mssql_server.this.id
  subresource_names              = ["sqlServer"]
  private_dns_zone_id            = module.sql_dns_zone.id
  tags                           = var.tags
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "sql_db" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "diag-${var.database_name}"
  target_resource_id         = azurerm_mssql_database.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = "Basic"
  }
}
