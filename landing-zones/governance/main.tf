#--------------------------------------------------------------
# AKS Landing Zone - Governance Module
# Custom Azure Policy Definitions & Assignments
#--------------------------------------------------------------

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

#--------------------------------------------------------------
locals {
  acr_registry_name       = element(reverse(split("/", var.acr_id)), 0)
  allowed_acr_image_regex = "^${local.acr_registry_name}\\.azurecr\\.io/.+$"
}

#--------------------------------------------------------------
# Custom Policy: Deny Pods Without Resource Limits
#--------------------------------------------------------------

resource "azurerm_policy_definition" "deny_pods_no_limits" {
  name         = "pol-deny-pods-no-resource-limits-${var.environment}"
  policy_type  = "Custom"
  mode         = "Microsoft.Kubernetes.Data"
  display_name = "Deny pods without resource limits"
  description  = "Deny the creation of pods that do not specify CPU and memory limits"

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Kubernetes"
  })

  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "The effect of the policy"
      }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Deny"
    }
    excludedNamespaces = {
      type = "Array"
      metadata = {
        displayName = "Excluded Namespaces"
        description = "Namespaces excluded from the policy"
      }
      defaultValue = ["kube-system", "gatekeeper-system", "azure-arc", "ingress-nginx"]
    }
  })

  policy_rule = jsonencode({
    if = {
      field = "type"
      in    = ["Microsoft.ContainerService/managedClusters"]
    }
    then = {
      effect = "[parameters('effect')]"
      details = {
        templateInfo = {
          sourceType = "PublicURL"
          url        = "https://store.policy.core.windows.net/kubernetes/container-resource-limits/v1/template.yaml"
        }
        apiGroups          = [""]
        kinds              = ["Pod"]
        namespaces         = "[parameters('excludedNamespaces')]"
        excludedNamespaces = "[parameters('excludedNamespaces')]"
        values = {
          cpuLimit    = ""
          memoryLimit = ""
        }
      }
    }
  })
}

resource "azurerm_resource_policy_assignment" "deny_pods_no_limits" {
  name                 = "asgn-deny-no-limits-${var.environment}"
  resource_id          = var.cluster_id
  policy_definition_id = azurerm_policy_definition.deny_pods_no_limits.id
  display_name         = "Deny pods without resource limits"
  description          = "Ensures all pods have CPU and memory limits defined"
  location             = var.location

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
    excludedNamespaces = {
      value = ["kube-system", "gatekeeper-system", "azure-arc", "ingress-nginx"]
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

#--------------------------------------------------------------
# Custom Policy: Enforce Image Source from ACR Only
#--------------------------------------------------------------

resource "azurerm_policy_definition" "enforce_acr_images" {
  name         = "pol-enforce-acr-images-${var.environment}"
  policy_type  = "Custom"
  mode         = "Microsoft.Kubernetes.Data"
  display_name = "Enforce container images from ACR only"
  description  = "Only allow container images sourced from the designated Azure Container Registry"

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Kubernetes"
  })

  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "The effect of the policy"
      }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Deny"
    }
    allowedContainerImagesRegex = {
      type = "String"
      metadata = {
        displayName = "Allowed container image regex"
        description = "Regex pattern for allowed container image sources"
      }
      defaultValue = local.allowed_acr_image_regex
    }
    excludedNamespaces = {
      type = "Array"
      metadata = {
        displayName = "Excluded Namespaces"
        description = "Namespaces excluded from the policy"
      }
      defaultValue = ["kube-system", "gatekeeper-system", "azure-arc", "ingress-nginx"]
    }
  })

  policy_rule = jsonencode({
    if = {
      field = "type"
      in    = ["Microsoft.ContainerService/managedClusters"]
    }
    then = {
      effect = "[parameters('effect')]"
      details = {
        templateInfo = {
          sourceType = "PublicURL"
          url        = "https://store.policy.core.windows.net/kubernetes/container-allowed-images/v2/template.yaml"
        }
        apiGroups          = [""]
        kinds              = ["Pod"]
        excludedNamespaces = "[parameters('excludedNamespaces')]"
        values = {
          imageRegex = "[parameters('allowedContainerImagesRegex')]"
        }
      }
    }
  })
}

resource "azurerm_resource_policy_assignment" "enforce_acr_images" {
  name                 = "asgn-enforce-acr-${var.environment}"
  resource_id          = var.cluster_id
  policy_definition_id = azurerm_policy_definition.enforce_acr_images.id
  display_name         = "Enforce container images from ACR only"
  description          = "Only container images from the designated ACR are allowed"
  location             = var.location

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
    allowedContainerImagesRegex = {
      value = local.allowed_acr_image_regex
    }
    excludedNamespaces = {
      value = ["kube-system", "gatekeeper-system", "azure-arc", "ingress-nginx"]
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

#--------------------------------------------------------------
# Azure Resource Graph Queries (Reference)
#
# These queries can be run in Azure Resource Graph Explorer
# to audit governance posture across the landing zone.
#
# Query 1: List all AKS clusters with their policy compliance
#   resources
#   | where type == "microsoft.containerservice/managedclusters"
#   | project name, resourceGroup, location, properties.kubernetesVersion
#
# Query 2: List non-compliant policy assignments
#   policyresources
#   | where type == "microsoft.policyinsights/policystates"
#   | where properties.complianceState == "NonCompliant"
#   | project policyAssignmentName=properties.policyAssignmentName,
#             resourceId=properties.resourceId
#   | summarize count() by policyAssignmentName
#
# Query 3: AKS clusters without network policy
#   resources
#   | where type == "microsoft.containerservice/managedclusters"
#   | where isnull(properties.networkProfile.networkPolicy) or
#           properties.networkProfile.networkPolicy == ""
#   | project name, resourceGroup
#--------------------------------------------------------------

#--------------------------------------------------------------
# Resource Group for Governance
#--------------------------------------------------------------

resource "azurerm_resource_group" "governance" {
  name     = "rg-governance-${var.environment}"
  location = var.location
  tags     = var.tags
}

