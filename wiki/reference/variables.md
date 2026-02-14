# Variables Reference

All Terraform input variables for the AKS Landing Zone Lab, defined in the root `variables.tf`.

---

## General

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment` | `string` | `"dev"` | Environment name (`dev`, `lab`, `prod`). Used in resource naming and tagging. |
| `location` | `string` | `"eastus"` | Azure region for all resources. |
| `project_name` | `string` | `"akslab"` | Project name used in the naming convention. Appears in all resource names. |
| `owner` | `string` | `"Jamon"` | Owner tag applied to all resources for cost tracking and contact purposes. |

---

## Networking

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `hub_vnet_cidr` | `string` | `"10.0.0.0/16"` | CIDR block for the hub VNet. Contains management, shared services, and firewall subnets. |
| `spoke_aks_vnet_cidr` | `string` | `"10.1.0.0/16"` | CIDR block for the AKS spoke VNet. Contains system pool, user pool, and ingress subnets. |

---

## Optional Toggles

These boolean variables enable or disable optional components. All are **OFF** by default in the dev environment to minimize cost.

| Variable | Type | Default | Cost Impact | Description |
|----------|------|---------|------------|-------------|
| `enable_firewall` | `bool` | `false` | +$900/mo | Enable Azure Firewall (Basic SKU) in the hub VNet for centralized egress filtering. |
| `enable_managed_prometheus` | `bool` | `false` | +$0–5/mo | Enable Azure Managed Prometheus for custom metrics collection and storage. |
| `enable_managed_grafana` | `bool` | `false` | +$10/mo | Enable Azure Managed Grafana for dashboards with Azure AD authentication. |
| `enable_defender` | `bool` | `false` | +$7/node/mo | Enable Microsoft Defender for Containers for runtime threat detection and image scanning. |
| `enable_dns_zone` | `bool` | `false` | +$0.50/mo | Enable Azure DNS Zone for custom domain names. Requires `dns_zone_name` to be set. |
| `enable_keda` | `bool` | `false` | Free | Enable KEDA (Kubernetes Event-Driven Autoscaling) for event-driven autoscaling beyond CPU/memory. |
| `enable_azure_files` | `bool` | `false` | +$1/mo | Enable Azure Files StorageClass for ReadWriteMany persistent volumes. |
| `enable_app_insights` | `bool` | `false` | +$0–5/mo | Enable Application Insights synthetic monitoring test. |

---

## AKS Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `kubernetes_version` | `string` | `"1.29"` | Kubernetes version for the AKS cluster. Check supported versions with `az aks get-versions --location eastus`. |
| `system_node_pool_vm_size` | `string` | `"Standard_B2s"` | VM size for the system node pool. Burstable B-series recommended for lab workloads. |
| `user_node_pool_vm_size` | `string` | `"Standard_B2s"` | VM size for the user node pool. Runs application workloads. |
| `system_node_pool_min` | `number` | `1` | Minimum number of nodes in the system pool (autoscaler lower bound). |
| `system_node_pool_max` | `number` | `2` | Maximum number of nodes in the system pool (autoscaler upper bound). |
| `user_node_pool_min` | `number` | `1` | Minimum number of nodes in the user pool (autoscaler lower bound). |
| `user_node_pool_max` | `number` | `3` | Maximum number of nodes in the user pool (autoscaler upper bound). |

---

## DNS

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `dns_zone_name` | `string` | `""` | DNS zone name (e.g., `mylab.example.com`). Required if `enable_dns_zone = true`. |

---

## Alerting & Cost

| Variable | Type | Default | Validation | Description |
|----------|------|---------|------------|-------------|
| `alert_email` | `string` | `"admin@example.com"` | Must be a valid email | Email address for alert notifications. Used by the Action Group. |
| `budget_amount` | `number` | `100` | — | Monthly budget threshold in USD. Alert fires when spend approaches this amount. |

---

## Environment Files

Variable values are set per environment in `environments/`:

### dev.tfvars (Budget-Safe Defaults)

```hcl
environment                 = "dev"
location                    = "eastus"
project_name                = "akslab"
owner                       = "Jamon"
hub_vnet_cidr               = "10.0.0.0/16"
spoke_aks_vnet_cidr         = "10.1.0.0/16"
kubernetes_version          = "1.29"
system_node_pool_vm_size    = "Standard_B2s"
user_node_pool_vm_size      = "Standard_B2s"
system_node_pool_min        = 1
system_node_pool_max        = 2
user_node_pool_min          = 1
user_node_pool_max          = 3
alert_email                 = ""
budget_amount               = 100
enable_firewall             = false
enable_managed_prometheus   = false
enable_managed_grafana      = false
enable_defender             = false
enable_dns_zone             = false
enable_keda                 = false
enable_azure_files          = false
enable_app_insights         = false
```

**Estimated cost**: ~$80–100/mo (always-on), ~$55–75 (with stop/start)

### lab.tfvars (Extended Features)

```hcl
environment                 = "lab"
budget_amount               = 130
enable_managed_prometheus   = true
enable_managed_grafana      = true
enable_dns_zone             = true
enable_keda                 = true
enable_azure_files          = true
# All other values same as dev
```

**Estimated cost**: ~$105–130/mo

---

## Usage

```powershell
# Deploy with dev defaults
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Deploy with lab features
terraform plan -var-file="environments/lab.tfvars"
terraform apply -var-file="environments/lab.tfvars"

# Override a single variable
terraform apply -var-file="environments/dev.tfvars" -var="enable_managed_grafana=true"

# Use the deploy script
.\scripts\deploy.ps1 -Environment dev
.\scripts\deploy.ps1 -Environment lab
```
