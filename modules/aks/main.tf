# -----------------------------------------------------------------------------
# Module: aks
# Description: Creates an AKS cluster with system and user node pools,
#              OIDC, workload identity, CNI overlay, Calico, and maintenance window
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = var.system_pool.name
    vm_size             = var.system_pool.vm_size
    node_count          = var.system_pool.node_count
    min_count           = var.system_pool.min_count
    max_count           = var.system_pool.max_count
    enable_auto_scaling = var.system_pool.enable_auto_scaling
    os_disk_size_gb     = var.system_pool.os_disk_size_gb
    vnet_subnet_id      = var.subnet_ids["system"]
    zones               = var.system_pool.zones

    node_labels = {
      "nodepool-type" = "system"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
    pod_cidr            = "192.168.0.0/16"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  auto_scaler_profile {
    balance_similar_node_groups = true
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3, 4]
    }
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = var.user_pool.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_pool.vm_size
  node_count            = var.user_pool.node_count
  min_count             = var.user_pool.min_count
  max_count             = var.user_pool.max_count
  enable_auto_scaling   = var.user_pool.enable_auto_scaling
  os_disk_size_gb       = var.user_pool.os_disk_size_gb
  vnet_subnet_id        = var.subnet_ids["user"]
  zones                 = var.user_pool.zones
  mode                  = "User"

  node_labels = {
    "nodepool-type" = "user"
  }

  tags = var.tags
}
