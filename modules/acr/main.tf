# -----------------------------------------------------------------------------
# Module: acr
# Description: Creates an Azure Container Registry with AcrPull role assignment
# -----------------------------------------------------------------------------

resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false

  tags = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  count                = var.principal_id != null ? 1 : 0
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = var.principal_id
}
