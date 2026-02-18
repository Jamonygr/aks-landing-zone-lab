<div align="center">
  <img src="../images/wiki-landing-zones.svg" alt="Landing Zones" width="900"/>
</div>

<div align="center">

[![Zones](https://img.shields.io/badge/Landing_Zones-7-blue?style=for-the-badge)](.)
[![Optional](https://img.shields.io/badge/Data_Zone-Optional-orange?style=for-the-badge)](.)
[![CAF](https://img.shields.io/badge/Pattern-Cloud_Adoption_Framework-green?style=for-the-badge)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

</div>

# 🏗️ Landing Zones

The root module orchestrates **7 landing zones**.  
`landing-zones/data` is optional and deploys only when `enable_sql_database = true`.

---

## 🌐 Dependency Flow

```text
1. networking
   -> 2. aks-platform
      -> 3. management
      -> 4. security
      -> 5. governance
      -> 6. identity
3 + 4 + 6 (+ networking outputs)
   -> 7. data (optional)
```

---

## 📚 Landing Zone Details

### 1) Networking (`landing-zones/networking`)

Purpose: foundational hub-spoke network, subnet segmentation, NSGs, route table, optional firewall.

Key resources:
- `rg-hub-networking-{env}` and `rg-spoke-aks-networking-{env}`
- Hub VNet (`10.0.0.0/16`) and spoke VNet (`10.1.0.0/16`)
- Subnets: `snet-management`, `snet-shared-services`, `AzureFirewallSubnet`, `AzureFirewallManagementSubnet` (optional), `snet-aks-system`, `snet-aks-user`, `snet-ingress`, `snet-private-endpoints`
- NSGs for system, user, ingress, and private endpoints
- Route table `rt-spoke-aks-{env}` with:
  - `to-hub` route when firewall is enabled
  - `to-internet` route using Internet by default or firewall when `route_internet_via_firewall = true`
- Hub<->spoke VNet peering
- Optional Azure Firewall Basic + firewall policy/rules

Key outputs:
- VNet IDs, AKS subnet IDs, private endpoint subnet ID, spoke RG name

Dependencies:
- none

---

### 2) AKS Platform (`landing-zones/aks-platform`)

Purpose: Kubernetes platform + image registry + ingress + optional DNS zone.

Key resources:
- AKS cluster (`kubernetes_version` variable, default `1.32`)
- System and user node pools (autoscaling, AzureLinux OS)
- Azure CNI Overlay + Calico (`pod_cidr=192.168.0.0/16`, `service_cidr=172.16.0.0/16`)
- OIDC issuer and workload identity enabled
- Azure RBAC enabled for AKS
- ACR (Basic SKU) + `AcrPull` assignment for kubelet identity
- NGINX ingress Helm release + static public IP
- Optional Azure DNS zone with `ingress` and wildcard A records

Key outputs:
- Cluster ID/name/FQDN, kube admin creds (sensitive), kubelet object ID, OIDC issuer URL, ACR ID/login server, ingress public IP

Dependencies:
- networking subnet IDs
- management Log Analytics workspace ID

---

### 3) Management (`landing-zones/management`)

Purpose: centralized observability, alerting, and budget controls.

Key resources:
- `rg-management-{env}`
- Log Analytics workspace + Container Insights solution
- AKS diagnostic settings (when `enable_cluster_alerts = true`)
- Subscription activity log diagnostics
- Action group for email notifications
- Metric alerts (node readiness, CPU, memory) when cluster alerts are enabled
- Scheduled query alerts (pod restarts, failed pods, OOMKilled, API 5xx, image pull failures) when cluster alerts are enabled
- Log ingestion cap alert
- Resource-group budget with threshold notifications
- Optional Azure Managed Prometheus workspace + DCE + DCR
- Optional Azure Managed Grafana (requires Prometheus)

Key outputs:
- Log Analytics workspace ID/name, action group ID, optional Grafana endpoint, optional Prometheus workspace ID

Dependencies:
- AKS cluster ID

---

### 4) Security (`landing-zones/security`)

Purpose: security baseline, secrets management, and optional runtime protection.

Key resources:
- `rg-security-{env}`
- Pod Security Baseline Azure Policy assignment (audit effect)
- Key Vault (RBAC-enabled)
- Key Vault role assignments:
  - AKS kubelet identity
  - additional identities passed from root (currently workload identity principal)
  - deployer as Key Vault Administrator
- CSI Secrets Store driver + Azure provider Helm releases
- Sample Key Vault secret (`sample-secret`)
- Optional Defender for Containers pricing tier

Key outputs:
- Key Vault ID/name/URI, policy assignment ID

Dependencies:
- AKS cluster ID and kubelet identity object ID

---

### 5) Governance (`landing-zones/governance`)

Purpose: custom Kubernetes policy definitions and assignments at cluster scope.

Key resources:
- `rg-governance-{env}`
- Custom policy definition: deny pods without resource limits
- Custom policy definition: allow images only from project ACR regex
- Resource policy assignments (currently configured with `Audit` effect)

Key outputs:
- Policy definition and assignment IDs

Dependencies:
- AKS cluster ID and ACR ID

---

### 6) Identity (`landing-zones/identity`)

Purpose: workload identity federation and demo storage access.

Key resources:
- `rg-identity-{env}`
- Workload user-assigned identity + federated credential
- Metrics app user-assigned identity + federated credential
- Storage account + private blob container (`metrics-data`)
- RBAC assignments for metrics identity:
  - `Storage Blob Data Contributor`
  - `Storage Queue Data Contributor`

Key outputs:
- Workload and metrics identity client/principal IDs, metrics storage account/container names

Dependencies:
- AKS cluster name and OIDC issuer URL

---

### 7) Data (Optional) (`landing-zones/data`)

Purpose: private Azure SQL database for application scenarios.

Key resources (only when `enable_sql_database = true`):
- `rg-data-{env}`
- SQL server + `learninghub` database (via `modules/sql-database`)
- Private endpoint in `snet-private-endpoints`
- Private DNS zone link (`privatelink.database.windows.net`)
- SQL diagnostics to Log Analytics
- Key Vault secret `sql-connection-string`

Key outputs:
- SQL server FQDN and database name (empty string when disabled), data resource group name

Dependencies:
- networking private endpoint subnet and VNet IDs
- management Log Analytics workspace ID
- security Key Vault ID
- identity workload principal ID

---

## 🚀 Deployment Order

Terraform resolves this graph automatically:

1. `networking`
2. `aks-platform`
3. `management`, `security`, `governance`, and `identity` in parallel
4. `data` (optional, after required upstream outputs are available)

---

<div align="center">

**[&larr; Wiki Home](../README.md)** &nbsp;&nbsp;|&nbsp;&nbsp; **[Modules &rarr;](../modules/README.md)**

</div>
