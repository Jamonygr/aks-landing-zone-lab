# Outputs Reference

All Terraform outputs exported by the AKS Landing Zone Lab root module, defined in `outputs.tf`.

---

## Cluster

| Output | Type | Description | Example Value |
|--------|------|-------------|---------------|
| `cluster_name` | `string` | The name of the AKS cluster | `aks-akslab-dev` |
| `cluster_fqdn` | `string` | The fully qualified domain name of the AKS API server | `aks-akslab-dev-abc123.hcp.eastus.azmk8s.io` |
| `kubeconfig_command` | `string` | Command to fetch kubeconfig for kubectl | `az aks get-credentials --resource-group rg-spoke-aks-networking-dev --name aks-akslab-dev` |

### Usage

```powershell
# Get the cluster name
terraform output cluster_name

# Copy & run the kubeconfig command
terraform output -raw kubeconfig_command | Invoke-Expression

# Or use the get-credentials script
.\scripts\get-credentials.ps1
```

---

## Networking

| Output | Type | Description | Example Value |
|--------|------|-------------|---------------|
| `hub_vnet_id` | `string` | Azure resource ID of the hub VNet | `/subscriptions/.../resourceGroups/rg-hub-networking-dev/providers/Microsoft.Network/virtualNetworks/vnet-hub-dev` |
| `spoke_vnet_id` | `string` | Azure resource ID of the spoke VNet | `/subscriptions/.../resourceGroups/rg-spoke-aks-networking-dev/providers/Microsoft.Network/virtualNetworks/vnet-spoke-aks-dev` |
| `ingress_public_ip` | `string` | The public IP address assigned to the NGINX ingress controller's Load Balancer | `20.85.123.45` |

### Usage

```powershell
# Get the ingress public IP to access applications
$ip = terraform output -raw ingress_public_ip
curl "http://$ip" -H "Host: hello-web.local"

# Use the VNet IDs for cross-referencing
terraform output hub_vnet_id
terraform output spoke_vnet_id
```

---

## Container Registry

| Output | Type | Description | Example Value |
|--------|------|-------------|---------------|
| `acr_login_server` | `string` | The login server URL for the Azure Container Registry | `acrakslabdev.azurecr.io` |

### Usage

```powershell
# Get the ACR login server
$acr = terraform output -raw acr_login_server

# Login to ACR
az acr login --name ($acr -split '\.')[0]

# Tag and push an image
docker tag myapp:latest "${acr}/myapp:v1"
docker push "${acr}/myapp:v1"

# Verify AKS can pull from ACR
az aks check-acr -g rg-spoke-aks-networking-dev -n aks-akslab-dev --acr $acr
```

---

## Monitoring

| Output | Type | Description | Example Value |
|--------|------|-------------|---------------|
| `log_analytics_workspace_id` | `string` | Azure resource ID of the Log Analytics workspace | `/subscriptions/.../resourceGroups/rg-management-dev/providers/Microsoft.OperationalInsights/workspaces/law-aks-dev` |
| `grafana_endpoint` | `string` | The URL of the Azure Managed Grafana instance (empty if disabled) | `https://akslab-dev-abc123.eus.grafana.azure.com` |

### Usage

```powershell
# Get the Log Analytics workspace ID for KQL queries
terraform output log_analytics_workspace_id

# Open Grafana (if enabled)
$grafana = terraform output -raw grafana_endpoint
if ($grafana) { Start-Process $grafana }
```

---

## Output Sources

Each output is sourced from a specific landing zone module:

| Output | Source Module | Source Output |
|--------|-------------|--------------|
| `cluster_name` | `module.aks_platform` | `cluster_name` |
| `cluster_fqdn` | `module.aks_platform` | `cluster_fqdn` |
| `kubeconfig_command` | Computed | Uses `module.networking` + `module.aks_platform` |
| `hub_vnet_id` | `module.networking` | `hub_vnet_id` |
| `spoke_vnet_id` | `module.networking` | `spoke_vnet_id` |
| `ingress_public_ip` | `module.aks_platform` | `ingress_public_ip` |
| `acr_login_server` | `module.aks_platform` | `acr_login_server` |
| `log_analytics_workspace_id` | `module.management` | `log_analytics_workspace_id` |
| `grafana_endpoint` | `module.management` | `grafana_endpoint` |

---

## Accessing Outputs

```powershell
# List all outputs
terraform output

# Get a specific output as plain text (no quotes)
terraform output -raw cluster_name

# Get all outputs as JSON
terraform output -json

# Use in PowerShell variables
$clusterName = terraform output -raw cluster_name
$ingressIp = terraform output -raw ingress_public_ip
$acrServer = terraform output -raw acr_login_server
```

---

## Downstream Usage

These outputs are commonly used in subsequent operations:

| Operation | Outputs Used |
|-----------|-------------|
| Get kubectl credentials | `kubeconfig_command` |
| Access the application | `ingress_public_ip` |
| Push container images | `acr_login_server` |
| Run KQL queries | `log_analytics_workspace_id` |
| View Grafana dashboards | `grafana_endpoint` |
| Verify VNet peering | `hub_vnet_id`, `spoke_vnet_id` |
| Script automation | All outputs via `terraform output -json` |
