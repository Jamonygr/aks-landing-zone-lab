# -----------------------------------------------------------------------------
# Module: storage
# Description: Creates an Azure Storage Account
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}
