#--------------------------------------------------------------
# AKS Landing Zone - AKS Platform Module
# AKS Cluster, ACR, NGINX Ingress, DNS
#--------------------------------------------------------------

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

#--------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------

data "azurerm_client_config" "current" {}

#--------------------------------------------------------------
# AKS Cluster
#--------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  # Managed Identity
  identity {
    type = "SystemAssigned"
  }

  # Default (System) Node Pool
  default_node_pool {
    name                        = "system"
    vm_size                     = var.system_node_vm_size
    auto_scaling_enabled        = true
    min_count                   = var.system_node_min_count
    max_count                   = var.system_node_max_count
    vnet_subnet_id              = var.aks_system_subnet_id
    os_disk_size_gb             = 30
    os_sku                      = "AzureLinux"
    temporary_name_for_rotation = "systemtmp"

    node_labels = {
      "nodepool" = "system"
    }

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  # Azure CNI Overlay Networking
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
  }

  # RBAC & Azure AD Integration
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  # OIDC & Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Auto-upgrade
  automatic_upgrade_channel = "patch"

  # Maintenance Window
  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "03:00"
    utc_offset  = "+00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "03:00"
    utc_offset  = "+00:00"
  }

  # OMS Agent for Container Insights
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
    ]
  }
}

#--------------------------------------------------------------
# User Node Pool
#--------------------------------------------------------------

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_vm_size
  auto_scaling_enabled  = true
  min_count             = var.user_node_min_count
  max_count             = var.user_node_max_count
  vnet_subnet_id        = var.aks_user_subnet_id
  os_disk_size_gb       = 30
  os_sku                = "AzureLinux"
  mode                  = "User"
  tags                  = var.tags

  node_labels = {
    "nodepool" = "user"
    "workload" = "applications"
  }

  node_taints = [
    "workload=applications:PreferNoSchedule"
  ]

  upgrade_settings {
    max_surge                     = "10%"
    drain_timeout_in_minutes      = 0
    node_soak_duration_in_minutes = 0
  }

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}

#--------------------------------------------------------------
# Azure Container Registry (Basic SKU)
#--------------------------------------------------------------

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

#--------------------------------------------------------------
# AcrPull Role Assignment for AKS Kubelet Identity
#--------------------------------------------------------------

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

#--------------------------------------------------------------
# Public IP for NGINX Ingress Controller
#--------------------------------------------------------------

resource "azurerm_public_ip" "ingress" {
  name                = "pip-ingress-${var.cluster_name}"
  location            = var.location
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

#--------------------------------------------------------------
# NGINX Ingress Controller (Helm)
#--------------------------------------------------------------

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.11.3"
  timeout          = 600

  set {
    name  = "controller.replicaCount"
    value = "2"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.ingress.ip_address
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = azurerm_kubernetes_cluster.main.node_resource_group
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }

  set {
    name  = "controller.nodeSelector.nodepool"
    value = "user"
  }

  set {
    name  = "controller.tolerations[0].key"
    value = "workload"
  }

  set {
    name  = "controller.tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "controller.tolerations[0].value"
    value = "applications"
  }

  set {
    name  = "controller.tolerations[0].effect"
    value = "PreferNoSchedule"
  }

  set {
    name  = "controller.admissionWebhooks.patch.nodeSelector.nodepool"
    value = "system"
  }

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_kubernetes_cluster_node_pool.user,
  ]
}

#--------------------------------------------------------------
# Optional DNS Zone + A Record
#--------------------------------------------------------------

resource "azurerm_dns_zone" "main" {
  count               = var.enable_dns_zone ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_dns_a_record" "ingress" {
  count               = var.enable_dns_zone ? 1 : 0
  name                = "ingress"
  zone_name           = azurerm_dns_zone.main[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.ingress.id
}

resource "azurerm_dns_a_record" "wildcard" {
  count               = var.enable_dns_zone ? 1 : 0
  name                = "*"
  zone_name           = azurerm_dns_zone.main[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.ingress.id
}
