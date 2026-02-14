# -----------------------------------------------------------------------------
# Module: resource-group
# Description: Creates an Azure Resource Group
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location

  tags = var.tags
}
