#--------------------------------------------------------------
# AKS Landing Zone - Security Module
# Azure Policy, Defender, Key Vault, CSI Secrets Store
#--------------------------------------------------------------

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

#--------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

#--------------------------------------------------------------
# Resource Group
#--------------------------------------------------------------

resource "azurerm_resource_group" "security" {
  name     = "rg-security-${var.environment}"
  location = var.location
  tags     = var.tags
}

#--------------------------------------------------------------
# Azure Policy Assignment - Pod Security Baseline
#--------------------------------------------------------------

resource "azurerm_resource_policy_assignment" "pod_security_baseline" {
  name                 = "pol-pod-security-baseline-${var.environment}"
  resource_id          = var.cluster_id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d" # Kubernetes cluster pod security baseline standards for Linux-based workloads
  display_name         = "Kubernetes cluster pod security baseline standards"
  description          = "Enforce pod security baseline standards on the AKS cluster"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })

  identity {
    type = "SystemAssigned"
  }

  location = var.location
}

#--------------------------------------------------------------
# Optional: Microsoft Defender for Containers
#--------------------------------------------------------------

resource "azurerm_security_center_subscription_pricing" "containers" {
  count         = var.enable_defender ? 1 : 0
  tier          = "Standard"
  resource_type = "Containers"
}

#--------------------------------------------------------------
# Azure Key Vault
#--------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                          = "kv-aks-${var.environment}-${substr(md5(data.azurerm_subscription.current.id), 0, 6)}"
  location                      = azurerm_resource_group.security.location
  resource_group_name           = azurerm_resource_group.security.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  rbac_authorization_enabled    = true
  public_network_access_enabled = true
  tags                          = var.tags
}

#--------------------------------------------------------------
# Key Vault RBAC - AKS Identity
#--------------------------------------------------------------

# Key Vault Secrets User role for AKS cluster identity
resource "azurerm_role_assignment" "aks_kv_secrets_user" {
  scope                            = azurerm_key_vault.main.id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = var.cluster_identity_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "additional_kv_secrets_users" {
  for_each = {
    for idx, object_id in var.additional_key_vault_secrets_user_object_ids :
    tostring(idx) => object_id
  }

  scope                            = azurerm_key_vault.main.id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = each.value
  skip_service_principal_aad_check = true
}

# Key Vault Administrator for current deployer
resource "azurerm_role_assignment" "deployer_kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

#--------------------------------------------------------------
# CSI Secrets Store Provider (Helm)
#--------------------------------------------------------------

resource "helm_release" "csi_secrets_store" {
  name             = "csi-secrets-store"
  repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart            = "secrets-store-csi-driver"
  namespace        = "kube-system"
  create_namespace = false
  version          = "1.4.7"
  timeout          = 300

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  set {
    name  = "enableSecretRotation"
    value = "true"
  }

  set {
    name  = "rotationPollInterval"
    value = "2m"
  }

  set {
    name  = "tokenRequests[0].audience"
    value = "api://AzureADTokenExchange"
  }
}

resource "helm_release" "csi_secrets_store_azure" {
  name             = "csi-secrets-store-provider-azure"
  repository       = "https://azure.github.io/secrets-store-csi-driver-provider-azure/charts"
  chart            = "csi-secrets-store-provider-azure"
  namespace        = "kube-system"
  create_namespace = false
  version          = "1.5.5"
  timeout          = 300

  set {
    name  = "secrets-store-csi-driver.install"
    value = "false"
  }

  depends_on = [helm_release.csi_secrets_store]
}

#--------------------------------------------------------------
# Sample Key Vault Secret (for testing)
#--------------------------------------------------------------

resource "azurerm_key_vault_secret" "sample" {
  name         = "sample-secret"
  value        = "Hello-from-AKS-Landing-Zone"
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [azurerm_role_assignment.deployer_kv_admin]
}

