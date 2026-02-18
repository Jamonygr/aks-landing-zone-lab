#--------------------------------------------------------------
# AKS Landing Zone - Data Module
# Azure SQL Database for Learning Hub
#--------------------------------------------------------------

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

#--------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------

data "azurerm_client_config" "current" {}

#--------------------------------------------------------------
# Resource Group
#--------------------------------------------------------------

resource "azurerm_resource_group" "data" {
  name     = "rg-data-${var.environment}"
  location = var.location
  tags     = var.tags
}

#--------------------------------------------------------------
# Azure SQL Database (Optional)
#--------------------------------------------------------------

module "sql_database" {
  count  = var.enable_sql_database ? 1 : 0
  source = "../../modules/sql-database"

  server_name               = "sql-${var.environment}-${substr(md5("${data.azurerm_client_config.current.subscription_id}-${var.data_location != "" ? var.data_location : var.location}-v3"), 0, 8)}"
  database_name             = "learninghub"
  resource_group_name       = azurerm_resource_group.data.name
  location                  = var.data_location != "" ? var.data_location : var.location
  private_endpoint_location = var.location
  aad_admin_login           = var.aad_admin_login
  aad_admin_object_id       = data.azurerm_client_config.current.object_id
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  subnet_id                 = var.private_endpoints_subnet_id
  tags                      = var.tags

  vnet_ids = {
    hub   = var.hub_vnet_id
    spoke = var.spoke_vnet_id
  }

  log_analytics_workspace_id = var.log_analytics_workspace_id
  enable_diagnostics         = var.enable_diagnostics
}

#--------------------------------------------------------------
# Key Vault Secrets - Store connection strings
#--------------------------------------------------------------

resource "azurerm_key_vault_secret" "sql_connection_string" {
  count        = var.enable_sql_database ? 1 : 0
  name         = "sql-connection-string"
  value        = module.sql_database[0].connection_string
  key_vault_id = var.key_vault_id
  tags         = var.tags
}
