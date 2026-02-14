# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  AKS Landing Zone Lab - Root Module                                        ║
# ║  Enterprise AKS environment with hub-spoke networking                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── Landing Zones ────────────────────────────────────────────────────────────

module "networking" {
  source = "./landing-zones/networking"

  environment         = var.environment
  location            = var.location
  tags                = local.tags
  hub_vnet_cidr       = var.hub_vnet_cidr
  spoke_aks_vnet_cidr = var.spoke_aks_vnet_cidr
  enable_firewall     = var.enable_firewall
}

module "aks_platform" {
  source = "./landing-zones/aks-platform"

  environment                = var.environment
  location                   = var.location
  tags                       = local.tags
  resource_group_name        = module.networking.spoke_resource_group_name
  aks_system_subnet_id       = module.networking.aks_system_subnet_id
  aks_user_subnet_id         = module.networking.aks_user_subnet_id
  ingress_subnet_id          = module.networking.ingress_subnet_id
  log_analytics_workspace_id = module.management.log_analytics_workspace_id
  acr_name                   = local.acr_name
  cluster_name               = local.cluster_name
  dns_prefix                 = local.dns_prefix
  kubernetes_version         = var.kubernetes_version
  system_node_vm_size        = var.system_node_pool_vm_size
  system_node_min_count      = var.system_node_pool_min
  system_node_max_count      = var.system_node_pool_max
  user_node_vm_size          = var.user_node_pool_vm_size
  user_node_min_count        = var.user_node_pool_min
  user_node_max_count        = var.user_node_pool_max
  enable_dns_zone            = var.enable_dns_zone
  dns_zone_name              = var.dns_zone_name

  depends_on = [module.networking]
}

module "management" {
  source = "./landing-zones/management"

  environment               = var.environment
  location                  = var.location
  tags                      = local.tags
  cluster_id                = module.aks_platform.cluster_id
  enable_cluster_alerts     = true
  enable_managed_prometheus = var.enable_managed_prometheus
  enable_managed_grafana    = var.enable_managed_grafana
  alert_email               = var.alert_email
  budget_amount             = var.budget_amount
}

module "security" {
  source = "./landing-zones/security"

  environment         = var.environment
  location            = var.location
  tags                = local.tags
  cluster_id          = module.aks_platform.cluster_id
  cluster_identity_id = module.aks_platform.kubelet_identity_object_id
  enable_defender     = var.enable_defender

  depends_on = [module.aks_platform]
}

module "governance" {
  source = "./landing-zones/governance"

  environment = var.environment
  location    = var.location
  tags        = local.tags
  cluster_id  = module.aks_platform.cluster_id
  acr_id      = module.aks_platform.acr_id

  depends_on = [module.aks_platform]
}

module "identity" {
  source = "./landing-zones/identity"

  environment         = var.environment
  location            = var.location
  tags                = local.tags
  cluster_name        = module.aks_platform.cluster_name
  oidc_issuer_url     = module.aks_platform.oidc_issuer_url
  resource_group_name = module.networking.spoke_resource_group_name

  depends_on = [module.aks_platform]
}
