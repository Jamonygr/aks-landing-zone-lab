# -----------------------------------------------------------------------------
# Module: keyvault
# Description: Creates an Azure Key Vault with RBAC authorization and role assignments
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = var.sku_name
  enable_rbac_authorization  = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  tags = var.tags
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  for_each             = toset(var.principal_ids)
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}
