# -----------------------------------------------------------------------------
# Module: monitoring/nsg-flow-logs
# Description: Creates NSG Flow Logs with Log Analytics integration
# -----------------------------------------------------------------------------

resource "azurerm_network_watcher_flow_log" "this" {
  name                      = var.name
  network_watcher_name      = var.network_watcher_name
  resource_group_name       = var.resource_group_name
  network_security_group_id = var.nsg_id
  storage_account_id        = var.storage_account_id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.retention_days
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.log_analytics_workspace_id
    workspace_region      = "eastus"
    workspace_resource_id = var.log_analytics_workspace_id
    interval_in_minutes   = 10
  }
}
