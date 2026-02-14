# -----------------------------------------------------------------------------
# Variables: aks
# -----------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "location" {
  description = "Azure region for the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster."
  type        = string
}

variable "system_pool" {
  description = "Configuration for the system node pool."
  type = object({
    name                = string
    vm_size             = string
    node_count          = number
    min_count           = number
    max_count           = number
    enable_auto_scaling = bool
    os_disk_size_gb     = number
    zones               = list(string)
  })
}

variable "user_pool" {
  description = "Configuration for the user node pool."
  type = object({
    name                = string
    vm_size             = string
    node_count          = number
    min_count           = number
    max_count           = number
    enable_auto_scaling = bool
    os_disk_size_gb     = number
    zones               = list(string)
  })
}

variable "subnet_ids" {
  description = "Map of subnet IDs keyed by pool name (system, user)."
  type        = map(string)
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for Container Insights."
  type        = string
}

variable "tags" {
  description = "Tags to apply to AKS resources."
  type        = map(string)
  default     = {}
}
