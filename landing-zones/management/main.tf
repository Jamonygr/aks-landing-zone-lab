#--------------------------------------------------------------
# AKS Landing Zone - Management & Monitoring Module
# Log Analytics, Container Insights, Alerts, Budgets
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
# Resource Group
#--------------------------------------------------------------

resource "azurerm_resource_group" "management" {
  name     = "rg-management-${var.environment}"
  location = var.location
  tags     = var.tags
}

#--------------------------------------------------------------
# Log Analytics Workspace
#--------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-aks-${var.environment}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = var.log_analytics_daily_quota_gb
  tags                = var.tags
}

#--------------------------------------------------------------
# Log Analytics Solutions - Container Insights
#--------------------------------------------------------------

resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.management.location
  resource_group_name   = azurerm_resource_group.management.name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

#--------------------------------------------------------------
# AKS Diagnostic Settings
#--------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "aks_logs" {
  count                      = var.enable_cluster_alerts ? 1 : 0
  name                       = "diag-aks-management-${var.environment}"
  target_resource_id         = var.cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "guard"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

#--------------------------------------------------------------
# Activity Log Diagnostic Settings (Subscription-level)
#--------------------------------------------------------------

data "azurerm_subscription" "current" {}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "diag-activity-log-${var.environment}"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Policy"
  }
}

#--------------------------------------------------------------
# Action Group for Alerts
#--------------------------------------------------------------

resource "azurerm_monitor_action_group" "aks_alerts" {
  name                = "ag-aks-alerts-${var.environment}"
  resource_group_name = azurerm_resource_group.management.name
  short_name          = "aksalerts"
  tags                = var.tags

  email_receiver {
    name          = "aks-admin"
    email_address = var.alert_email
  }
}

#--------------------------------------------------------------
# Metric Alerts
#--------------------------------------------------------------

# Node Not Ready Alert
resource "azurerm_monitor_metric_alert" "node_not_ready" {
  count               = var.enable_cluster_alerts ? 1 : 0
  name                = "alert-node-not-ready-${var.environment}"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [var.cluster_id]
  description         = "Alert when a node is not in Ready state"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "kube_node_status_condition"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0

    dimension {
      name     = "status"
      operator = "Include"
      values   = ["NotReady"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.aks_alerts.id
  }
}

# CPU Utilization >80%
resource "azurerm_monitor_metric_alert" "cpu_high" {
  count               = var.enable_cluster_alerts ? 1 : 0
  name                = "alert-cpu-high-${var.environment}"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [var.cluster_id]
  description         = "Alert when node CPU utilization exceeds 80%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.aks_alerts.id
  }
}

# Memory Utilization >80%
resource "azurerm_monitor_metric_alert" "memory_high" {
  count               = var.enable_cluster_alerts ? 1 : 0
  name                = "alert-memory-high-${var.environment}"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [var.cluster_id]
  description         = "Alert when node memory utilization exceeds 80%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.aks_alerts.id
  }
}

#--------------------------------------------------------------
# Log-Based (Scheduled Query) Alerts
#--------------------------------------------------------------

# Pod Restart Count >5
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pod_restarts" {
  count                = var.enable_cluster_alerts ? 1 : 0
  name                 = "alert-pod-restarts-${var.environment}"
  resource_group_name  = azurerm_resource_group.management.name
  location             = azurerm_resource_group.management.location
  description          = "Alert when pod restart count exceeds 5 in 15 minutes"
  severity             = 2
  scopes               = [azurerm_log_analytics_workspace.main.id]
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  tags                 = var.tags

  criteria {
    query                   = <<-QUERY
      KubePodInventory
      | where PodRestartCount > 5
      | summarize RestartCount = max(PodRestartCount) by PodName = Name, Namespace, bin(TimeGenerated, 5m)
    QUERY
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.aks_alerts.id]
  }
}

# Failed Pods
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "failed_pods" {
  count                = var.enable_cluster_alerts ? 1 : 0
  name                 = "alert-failed-pods-${var.environment}"
  resource_group_name  = azurerm_resource_group.management.name
  location             = azurerm_resource_group.management.location
  description          = "Alert when there are failed pods in the cluster"
  severity             = 2
  scopes               = [azurerm_log_analytics_workspace.main.id]
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  tags                 = var.tags

  criteria {
    query                   = <<-QUERY
      KubePodInventory
      | where PodStatus == "Failed"
      | summarize FailedCount = count() by PodName = Name, Namespace, bin(TimeGenerated, 5m)
    QUERY
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.aks_alerts.id]
  }
}

# OOMKilled Containers
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "oomkilled" {
  count                = var.enable_cluster_alerts ? 1 : 0
  name                 = "alert-oomkilled-${var.environment}"
  resource_group_name  = azurerm_resource_group.management.name
  location             = azurerm_resource_group.management.location
  description          = "Alert when containers are OOMKilled"
  severity             = 2
  scopes               = [azurerm_log_analytics_workspace.main.id]
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  tags                 = var.tags

  criteria {
    query                   = <<-QUERY
      ContainerInventory
      | where ContainerState == "Failed" and ExitCode == 137
      | summarize OOMCount = count() by ContainerID, Name, bin(TimeGenerated, 5m)
    QUERY
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.aks_alerts.id]
  }
}

# API Server 5xx Errors
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "api_5xx" {
  count                = var.enable_cluster_alerts ? 1 : 0
  name                 = "alert-api-5xx-${var.environment}"
  resource_group_name  = azurerm_resource_group.management.name
  location             = azurerm_resource_group.management.location
  description          = "Alert when API server returns 5xx errors"
  severity             = 1
  scopes               = [azurerm_log_analytics_workspace.main.id]
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  tags                 = var.tags

  criteria {
    query                   = <<-QUERY
      AzureDiagnostics
      | where Category == "kube-apiserver"
      | extend logMessage = column_ifexists("log_s", "")
      | where logMessage contains "statusCode\":5"
      | summarize ErrorCount = count() by bin(TimeGenerated, 5m)
    QUERY
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.aks_alerts.id]
  }
}

# Image Pull Failure
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "image_pull_failure" {
  count                = var.enable_cluster_alerts ? 1 : 0
  name                 = "alert-image-pull-failure-${var.environment}"
  resource_group_name  = azurerm_resource_group.management.name
  location             = azurerm_resource_group.management.location
  description          = "Alert when image pull failures occur"
  severity             = 2
  scopes               = [azurerm_log_analytics_workspace.main.id]
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  tags                 = var.tags

  criteria {
    query                   = <<-QUERY
      KubeEvents
      | where Reason in ("Failed", "BackOff") and Message contains "pulling image"
      | summarize FailureCount = count() by Name, Namespace, bin(TimeGenerated, 5m)
    QUERY
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.aks_alerts.id]
  }
}

#--------------------------------------------------------------
# Budget Alert ($100)
#--------------------------------------------------------------

resource "azurerm_consumption_budget_resource_group" "aks_budget" {
  name              = "budget-aks-${var.environment}"
  resource_group_id = azurerm_resource_group.management.id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = [var.alert_email]
  }

  lifecycle {
    ignore_changes = [
      time_period,
    ]
  }
}

#--------------------------------------------------------------
# Log Ingestion Cap Alert
#--------------------------------------------------------------

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "log_ingestion_cap" {
  name                 = "alert-log-ingestion-cap-${var.environment}"
  resource_group_name  = azurerm_resource_group.management.name
  location             = azurerm_resource_group.management.location
  scopes               = [azurerm_log_analytics_workspace.main.id]
  description          = "Alert when Log Analytics daily ingestion approaches the cap"
  severity             = 2
  evaluation_frequency = "PT1H"
  window_duration      = "P1D"
  tags                 = var.tags

  criteria {
    query                   = <<-QUERY
      Usage
      | where TimeGenerated > ago(1d)
      | where DataType != "Usage"
      | summarize IngestedGB = sum(Quantity) / 1024.0
    QUERY
    time_aggregation_method = "Total"
    operator                = "GreaterThan"
    threshold               = var.log_analytics_daily_quota_gb * 0.8
    metric_measure_column   = "IngestedGB"
  }

  action {
    action_groups = [azurerm_monitor_action_group.aks_alerts.id]
  }
}

#--------------------------------------------------------------
# NSG Flow Logs
#--------------------------------------------------------------

resource "azurerm_storage_account" "flow_logs" {
  name                     = "stflowlogs${var.environment}${substr(md5(azurerm_resource_group.management.id), 0, 6)}"
  resource_group_name      = azurerm_resource_group.management.name
  location                 = azurerm_resource_group.management.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

#--------------------------------------------------------------
# Optional: Azure Managed Prometheus
#--------------------------------------------------------------

resource "azurerm_monitor_workspace" "prometheus" {
  count               = var.enable_managed_prometheus ? 1 : 0
  name                = "amw-prometheus-${var.environment}"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location
  tags                = var.tags
}

resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  count                         = var.enable_managed_prometheus ? 1 : 0
  name                          = "dce-prometheus-${var.environment}"
  resource_group_name           = azurerm_resource_group.management.name
  location                      = azurerm_resource_group.management.location
  kind                          = "Linux"
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_monitor_data_collection_rule" "prometheus" {
  count               = var.enable_managed_prometheus ? 1 : 0
  name                = "dcr-prometheus-${var.environment}"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location
  kind                = "Linux"
  tags                = var.tags

  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus[0].id

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus[0].id
      name               = "MonitoringAccount"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount"]
  }
}

#--------------------------------------------------------------
# Optional: Azure Managed Grafana
#--------------------------------------------------------------

resource "azurerm_dashboard_grafana" "main" {
  count                             = var.enable_managed_grafana ? 1 : 0
  name                              = "grafana-aks-${var.environment}"
  resource_group_name               = azurerm_resource_group.management.name
  location                          = azurerm_resource_group.management.location
  grafana_major_version             = 11
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true
  tags                              = var.tags

  azure_monitor_workspace_integrations {
    resource_id = var.enable_managed_prometheus ? azurerm_monitor_workspace.prometheus[0].id : ""
  }

  identity {
    type = "SystemAssigned"
  }
}
