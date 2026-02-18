#--------------------------------------------------------------
# AKS Landing Zone - Identity Module
# Workload Identity Federation, Managed Identities
#--------------------------------------------------------------

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85"
    }
  }
}

#--------------------------------------------------------------
#--------------------------------------------------------------
# Resource Group for Identity Resources
#--------------------------------------------------------------

resource "azurerm_resource_group" "identity" {
  name     = "rg-identity-${var.environment}"
  location = var.location
  tags     = var.tags
}

#--------------------------------------------------------------
# User-Assigned Managed Identity - Workload Identity
#--------------------------------------------------------------

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-workload-${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.identity.location
  resource_group_name = azurerm_resource_group.identity.name
  tags                = var.tags
}

#--------------------------------------------------------------
# Federated Identity Credential - Workload Identity
#--------------------------------------------------------------

resource "azurerm_federated_identity_credential" "workload" {
  name      = "fic-workload-${var.cluster_name}"
  parent_id = azurerm_user_assigned_identity.workload.id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = var.oidc_issuer_url
  subject   = "system:serviceaccount:${var.workload_namespace}:${var.workload_service_account_name}"
}

#--------------------------------------------------------------
# User-Assigned Managed Identity - Metrics App
#--------------------------------------------------------------

resource "azurerm_user_assigned_identity" "metrics_app" {
  name                = "id-metrics-app-${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.identity.location
  resource_group_name = azurerm_resource_group.identity.name
  tags                = var.tags
}

#--------------------------------------------------------------
# Federated Identity Credential - Metrics App
#--------------------------------------------------------------

resource "azurerm_federated_identity_credential" "metrics_app" {
  name      = "fic-metrics-app-${var.cluster_name}"
  parent_id = azurerm_user_assigned_identity.metrics_app.id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = var.oidc_issuer_url
  subject   = "system:serviceaccount:${var.metrics_namespace}:${var.metrics_service_account_name}"
}

#--------------------------------------------------------------
# Storage Account for Metrics App
#--------------------------------------------------------------

resource "azurerm_storage_account" "metrics" {
  name                     = "stmetrics${var.environment}${substr(md5(azurerm_resource_group.identity.id), 0, 6)}"
  resource_group_name      = azurerm_resource_group.identity.name
  location                 = azurerm_resource_group.identity.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_container" "metrics_data" {
  name                  = "metrics-data"
  storage_account_id    = azurerm_storage_account.metrics.id
  container_access_type = "private"
}

#--------------------------------------------------------------
# Role Assignment - Metrics App -> Azure Storage
#--------------------------------------------------------------

# Storage Blob Data Contributor for the metrics app identity
resource "azurerm_role_assignment" "metrics_app_storage" {
  scope                            = azurerm_storage_account.metrics.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_user_assigned_identity.metrics_app.principal_id
  skip_service_principal_aad_check = true
}

# Storage Queue Data Contributor for the metrics app identity
resource "azurerm_role_assignment" "metrics_app_storage_queue" {
  scope                            = azurerm_storage_account.metrics.id
  role_definition_name             = "Storage Queue Data Contributor"
  principal_id                     = azurerm_user_assigned_identity.metrics_app.principal_id
  skip_service_principal_aad_check = true
}

