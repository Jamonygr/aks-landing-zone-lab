# -----------------------------------------------------------------------------
# Module: monitoring/alerts
# Description: Creates a configurable metric alert
# -----------------------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  scopes              = var.scopes
  description         = var.description
  severity            = var.severity
  frequency           = var.frequency
  window_size         = var.window_size

  criteria {
    metric_namespace = var.criteria.metric_namespace
    metric_name      = var.criteria.metric_name
    aggregation      = var.criteria.aggregation
    operator         = var.criteria.operator
    threshold        = var.criteria.threshold
  }

  action {
    action_group_id = var.action_group_id
  }
}
