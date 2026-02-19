<div align="center">
  <img src="../images/wiki-landing-zones.svg" alt="Landing Zones" width="900"/>
</div>

<div align="center">

[![Landing Zones](https://img.shields.io/badge/Landing_Zones-7-39f4ff?style=for-the-badge)](.)
[![Data Zone](https://img.shields.io/badge/Data_Zone-Optional-ff9657?style=for-the-badge)](.)
[![Pattern](https://img.shields.io/badge/Pattern-CAF_Aligned-a56fff?style=for-the-badge)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

</div>

# Landing Zones

The root stack orchestrates **7 landing zones** from `landing-zones/`:

1. `networking`
2. `aks-platform`
3. `management`
4. `security`
5. `governance`
6. `identity`
7. `data` (optional, enabled by `enable_sql_database = true`)

## Dependency Flow

```text
networking
  -> aks-platform
    -> management
    -> security
    -> governance
    -> identity
management + security + identity + networking outputs
  -> data (optional)
```

## Zone Summary

### 1) Networking (`landing-zones/networking`)

Purpose: hub-spoke foundation and traffic control.

Key points:

- Hub VNet `10.0.0.0/16`
- Spoke VNet `10.1.0.0/16`
- AKS/system/user/ingress/private-endpoint subnet segmentation
- NSGs and route table for spoke egress control
- Optional Azure Firewall (enabled in prod profile)

### 2) AKS Platform (`landing-zones/aks-platform`)

Purpose: cluster platform, registry, ingress, optional DNS.

Key points:

- AKS `kubernetes_version = 1.32`
- Azure CNI Overlay + Calico
- OIDC + workload identity enabled
- ACR and `AcrPull` assignment
- NGINX ingress Helm release with static Public IP
- Optional DNS zone (`enable_dns_zone`)

### 3) Management (`landing-zones/management`)

Purpose: observability and alerting baseline.

Key points:

- Log Analytics + Container Insights
- Metric alerts and scheduled query alerts
- Budget notifications (`budget_amount`)
- Optional managed Prometheus + managed Grafana

### 4) Security (`landing-zones/security`)

Purpose: baseline security controls and secrets path.

Key points:

- Key Vault (RBAC mode)
- Secrets Store CSI + Azure provider Helm releases
- Pod security baseline policy assignment
- Optional Defender for Containers

### 5) Governance (`landing-zones/governance`)

Purpose: custom policy controls scoped to the cluster.

Key points:

- Policy definition and assignment for resource limits
- Policy for allowed image sources (ACR pattern)
- Cluster-level policy assignments

### 6) Identity (`landing-zones/identity`)

Purpose: workload identity federation and data access role paths.

Key points:

- User-assigned identities and federated credentials
- Identity path for `learning-hub` service account
- Storage account/container and RBAC for metrics scenarios

### 7) Data (`landing-zones/data`, optional)

Purpose: private SQL path for application data.

Key points:

- SQL server + `learninghub` database
- Private endpoint + private DNS link
- SQL diagnostics to Log Analytics
- Key Vault secret for SQL connection string

## Environment Toggle View

From `environments/*.tfvars`:

| Feature | Dev | Lab | Prod |
|:--|:--:|:--:|:--:|
| `enable_firewall` | `false` | `false` | `true` |
| `enable_managed_prometheus` | `false` | `true` | `true` |
| `enable_managed_grafana` | `false` | `true` | `true` |
| `enable_defender` | `false` | `false` | `true` |
| `enable_dns_zone` | `false` | `true` | `true` |
| `enable_sql_database` | `false` | `true` | `true` |
| `enable_keda` | `false` | `true` | `true` |
| `enable_azure_files` | `false` | `true` | `true` |
| `enable_app_insights` | `false` | `false` | `true` |

## Deployment Order

Terraform resolves the graph automatically:

1. `networking`
2. `aks-platform`
3. `management`, `security`, `governance`, `identity` (parallel)
4. `data` (if enabled)

## Related Docs

- `../README.md`
- `../modules/README.md`
- `../reference/outputs.md`
