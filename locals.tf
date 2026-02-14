# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Local Values - Naming, Tags, Computed Values                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ─── Naming Convention ────────────────────────────────────────────────────
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = "aks-${local.name_prefix}"
  acr_name     = lower(replace("acr${var.project_name}${var.environment}", "-", ""))
  dns_prefix   = "${var.project_name}-${var.environment}"

  # ─── Resource Group Names ─────────────────────────────────────────────────
  hub_rg_name   = "rg-hub-${local.name_prefix}"
  spoke_rg_name = "rg-spoke-aks-${local.name_prefix}"
  mgmt_rg_name  = "rg-management-${local.name_prefix}"

  # ─── Network CIDRs ───────────────────────────────────────────────────────
  hub_subnets = {
    management      = cidrsubnet(var.hub_vnet_cidr, 8, 1) # 10.0.1.0/24
    shared_services = cidrsubnet(var.hub_vnet_cidr, 8, 2) # 10.0.2.0/24
    firewall        = cidrsubnet(var.hub_vnet_cidr, 8, 3) # 10.0.3.0/24
  }

  spoke_subnets = {
    aks_system = cidrsubnet(var.spoke_aks_vnet_cidr, 4, 0)  # 10.1.0.0/20
    aks_user   = cidrsubnet(var.spoke_aks_vnet_cidr, 4, 1)  # 10.1.16.0/20
    ingress    = cidrsubnet(var.spoke_aks_vnet_cidr, 8, 32) # 10.1.32.0/24
  }

  # ─── Tags ─────────────────────────────────────────────────────────────────
  tags = {
    project     = var.project_name
    environment = var.environment
    owner       = var.owner
    managed_by  = "terraform"
    lab         = "aks-landing-zone"
  }
}
