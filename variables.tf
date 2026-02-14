# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Input Variables                                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── General ──────────────────────────────────────────────────────────────────

variable "environment" {
  description = "Environment name (dev, lab, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "lab", "prod", "staging"], var.environment)
    error_message = "environment must be one of: dev, lab, prod, staging."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name used in naming convention"
  type        = string
  default     = "akslab"
}

variable "owner" {
  description = "Owner tag for cost tracking"
  type        = string
  default     = "Jamon"
}

# ─── Networking ───────────────────────────────────────────────────────────────

variable "hub_vnet_cidr" {
  description = "CIDR block for the hub VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "spoke_aks_vnet_cidr" {
  description = "CIDR block for the AKS spoke VNet"
  type        = string
  default     = "10.1.0.0/16"
}

# ─── Optional Toggles ────────────────────────────────────────────────────────

variable "enable_firewall" {
  description = "Enable Azure Firewall (Basic SKU) in hub - adds ~$900/mo"
  type        = bool
  default     = false
}

variable "enable_managed_prometheus" {
  description = "Enable Azure Managed Prometheus - adds ~$0-5/mo"
  type        = bool
  default     = false
}

variable "enable_managed_grafana" {
  description = "Enable Azure Managed Grafana - adds ~$10/mo"
  type        = bool
  default     = false
}

variable "enable_defender" {
  description = "Enable Defender for Containers - adds ~$7/node/mo"
  type        = bool
  default     = false
}

variable "enable_dns_zone" {
  description = "Enable Azure DNS Zone - adds ~$0.50/mo"
  type        = bool
  default     = false
}

variable "enable_cluster_alerts" {
  description = "Enable AKS cluster-specific alerts and diagnostics"
  type        = bool
  default     = true
}

variable "enable_keda" {
  description = "Enable KEDA for event-driven autoscaling - free"
  type        = bool
  default     = false
}

variable "enable_azure_files" {
  description = "Enable Azure Files StorageClass - adds ~$1/mo"
  type        = bool
  default     = false
}

variable "enable_app_insights" {
  description = "Enable Application Insights synthetic test - adds ~$0-5/mo"
  type        = bool
  default     = false
}

# ─── AKS ──────────────────────────────────────────────────────────────────────

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "system_node_pool_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "user_node_pool_vm_size" {
  description = "VM size for user node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "system_node_pool_min" {
  description = "Minimum nodes in system pool"
  type        = number
  default     = 1
}

variable "system_node_pool_max" {
  description = "Maximum nodes in system pool"
  type        = number
  default     = 2

  validation {
    condition     = var.system_node_pool_max >= var.system_node_pool_min
    error_message = "system_node_pool_max must be greater than or equal to system_node_pool_min."
  }
}

variable "user_node_pool_min" {
  description = "Minimum nodes in user pool"
  type        = number
  default     = 1
}

variable "user_node_pool_max" {
  description = "Maximum nodes in user pool"
  type        = number
  default     = 3

  validation {
    condition     = var.user_node_pool_max >= var.user_node_pool_min
    error_message = "user_node_pool_max must be greater than or equal to user_node_pool_min."
  }
}

# ─── DNS ──────────────────────────────────────────────────────────────────────

variable "dns_zone_name" {
  description = "DNS zone name (required if enable_dns_zone = true)"
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_dns_zone || length(trimspace(var.dns_zone_name)) > 0
    error_message = "dns_zone_name must be set when enable_dns_zone is true."
  }
}

# ─── Alerting ─────────────────────────────────────────────────────────────────

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = "admin@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "budget_amount" {
  description = "Monthly budget threshold in USD"
  type        = number
  default     = 100
}
