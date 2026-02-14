# -----------------------------------------------------------------------------
# Module: monitoring/action-group
# Description: Creates an Azure Monitor Action Group with email receiver
# -----------------------------------------------------------------------------

resource "azurerm_monitor_action_group" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  short_name          = var.short_name

  email_receiver {
    name          = "primary-email"
    email_address = var.email_address
  }

  tags = var.tags
}
