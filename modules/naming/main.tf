# -----------------------------------------------------------------------------
# Module: naming
# Description: Generates standardized resource names for AKS Landing Zone
# -----------------------------------------------------------------------------

locals {
  prefix = "${var.project_name}-${var.environment}"
  loc    = var.location

  names = {
    rg_hub      = "rg-${local.prefix}-hub-${local.loc}"
    rg_spoke    = "rg-${local.prefix}-spoke-${local.loc}"
    rg_mgmt     = "rg-${local.prefix}-mgmt-${local.loc}"
    vnet_hub    = "vnet-${local.prefix}-hub-${local.loc}"
    vnet_spoke  = "vnet-${local.prefix}-spoke-${local.loc}"
    snet_fw     = "AzureFirewallSubnet"
    snet_system = "snet-${local.prefix}-system-${local.loc}"
    snet_user   = "snet-${local.prefix}-user-${local.loc}"
    aks_cluster = "aks-${local.prefix}-${local.loc}"
    acr         = replace("acr${local.prefix}${local.loc}", "-", "")
    kv          = "kv-${local.prefix}-${local.loc}"
    law         = "law-${local.prefix}-${local.loc}"
    fw          = "fw-${local.prefix}-${local.loc}"
    pip_fw      = "pip-fw-${local.prefix}-${local.loc}"
    nsg_system  = "nsg-${local.prefix}-system-${local.loc}"
    nsg_user    = "nsg-${local.prefix}-user-${local.loc}"
    rt_spoke    = "rt-${local.prefix}-spoke-${local.loc}"
    st          = replace("st${local.prefix}${local.loc}", "-", "")
    ag          = "ag-${local.prefix}-${local.loc}"
    dns_zone    = "pdz-${local.prefix}-${local.loc}"
    ingress     = "ingress-${local.prefix}-${local.loc}"
    budget      = "budget-${local.prefix}"
    sql_server  = "sql-${local.prefix}-${local.loc}"
    sql_db      = "sqldb-${local.prefix}-${local.loc}"
    pe_sql      = "pe-sql-${local.prefix}-${local.loc}"
    rg_data     = "rg-${local.prefix}-data-${local.loc}"
  }
}
