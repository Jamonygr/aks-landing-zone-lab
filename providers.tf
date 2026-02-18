# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Provider Configuration                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
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

provider "helm" {
  kubernetes {
    host                   = module.aks_platform.kube_admin_config_host
    client_certificate     = base64decode(module.aks_platform.kube_admin_config_client_certificate)
    client_key             = base64decode(module.aks_platform.kube_admin_config_client_key)
    cluster_ca_certificate = base64decode(module.aks_platform.kube_admin_config_cluster_ca)
  }
}
