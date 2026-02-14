#--------------------------------------------------------------
# AKS Landing Zone - Identity Module Variables
#--------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    project    = "aks-landing-zone"
    managed_by = "terraform"
  }
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL from the AKS cluster for workload identity federation"
  type        = string
}

variable "workload_namespace" {
  description = "Kubernetes namespace for the workload identity service account"
  type        = string
  default     = "default"
}

variable "workload_service_account_name" {
  description = "Kubernetes service account name for workload identity"
  type        = string
  default     = "workload-sa"
}

variable "metrics_namespace" {
  description = "Kubernetes namespace for the metrics app service account"
  type        = string
  default     = "monitoring"
}

variable "metrics_service_account_name" {
  description = "Kubernetes service account name for the metrics app"
  type        = string
  default     = "metrics-app-sa"
}
