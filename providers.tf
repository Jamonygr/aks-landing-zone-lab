# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Provider Configuration                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azuread" {}

provider "helm" {
  kubernetes {
    host                   = module.aks_platform.kube_config_host
    client_certificate     = base64decode(module.aks_platform.kube_config_client_certificate)
    client_key             = base64decode(module.aks_platform.kube_config_client_key)
    cluster_ca_certificate = base64decode(module.aks_platform.kube_config_cluster_ca)
  }
}

provider "kubernetes" {
  host                   = module.aks_platform.kube_config_host
  client_certificate     = base64decode(module.aks_platform.kube_config_client_certificate)
  client_key             = base64decode(module.aks_platform.kube_config_client_key)
  cluster_ca_certificate = base64decode(module.aks_platform.kube_config_cluster_ca)
}
