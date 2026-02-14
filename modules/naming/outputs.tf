# -----------------------------------------------------------------------------
# Outputs: naming
# -----------------------------------------------------------------------------

output "rg_hub" {
  description = "Hub resource group name."
  value       = local.names.rg_hub
}

output "rg_spoke" {
  description = "Spoke resource group name."
  value       = local.names.rg_spoke
}

output "rg_mgmt" {
  description = "Management resource group name."
  value       = local.names.rg_mgmt
}

output "vnet_hub" {
  description = "Hub virtual network name."
  value       = local.names.vnet_hub
}

output "vnet_spoke" {
  description = "Spoke virtual network name."
  value       = local.names.vnet_spoke
}

output "snet_fw" {
  description = "Firewall subnet name (must be AzureFirewallSubnet)."
  value       = local.names.snet_fw
}

output "snet_system" {
  description = "AKS system node pool subnet name."
  value       = local.names.snet_system
}

output "snet_user" {
  description = "AKS user node pool subnet name."
  value       = local.names.snet_user
}

output "aks_cluster" {
  description = "AKS cluster name."
  value       = local.names.aks_cluster
}

output "acr" {
  description = "Azure Container Registry name."
  value       = local.names.acr
}

output "kv" {
  description = "Key Vault name."
  value       = local.names.kv
}

output "law" {
  description = "Log Analytics Workspace name."
  value       = local.names.law
}

output "fw" {
  description = "Azure Firewall name."
  value       = local.names.fw
}

output "pip_fw" {
  description = "Firewall public IP name."
  value       = local.names.pip_fw
}

output "nsg_system" {
  description = "System pool NSG name."
  value       = local.names.nsg_system
}

output "nsg_user" {
  description = "User pool NSG name."
  value       = local.names.nsg_user
}

output "rt_spoke" {
  description = "Spoke route table name."
  value       = local.names.rt_spoke
}

output "st" {
  description = "Storage account name."
  value       = local.names.st
}

output "ag" {
  description = "Action group name."
  value       = local.names.ag
}

output "dns_zone" {
  description = "Private DNS zone name."
  value       = local.names.dns_zone
}

output "ingress" {
  description = "Ingress controller name."
  value       = local.names.ingress
}

output "budget" {
  description = "Budget name."
  value       = local.names.budget
}
