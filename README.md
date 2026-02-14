# AKS Landing Zone Lab 🚀

[![Terraform CI/CD](https://github.com/Jamonygr/aks-landing-zone-lab/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/Jamonygr/aks-landing-zone-lab/actions/workflows/terraform-ci.yml)

> **Learn AKS with a hands-on, enterprise-grade Terraform lab.**  
> Deploys a complete AKS environment with hub-spoke networking, monitoring, security, GitOps, and chaos engineering — structured as Azure Landing Zones.

---

## Architecture

```mermaid
graph TB
    subgraph "Hub VNet - 10.0.0.0/16"
        FW[Azure Firewall<br/>Optional]
        MGMT[Management<br/>Subnet]
        SS[Shared Services<br/>Subnet]
    end

    subgraph "Spoke VNet - 10.1.0.0/16"
        subgraph "AKS Cluster"
            SYS[System Pool<br/>B2s 1-2 nodes]
            USR[User Pool<br/>B2s 1-3 nodes]
        end
        ING[Ingress Subnet<br/>NGINX]
    end

    subgraph "Platform Services"
        ACR[Container Registry<br/>Basic]
        KV[Key Vault]
        LAW[Log Analytics]
        PROM[Prometheus<br/>Optional]
        GRAF[Grafana<br/>Optional]
    end

    HUB_SPOKE[VNet Peering]
    
    Hub VNet --- HUB_SPOKE --- Spoke VNet
    ING -->|Public IP| INTERNET((Internet))
    AKS Cluster --> ACR
    AKS Cluster --> KV
    AKS Cluster --> LAW
    LAW --> PROM
    PROM --> GRAF
```

## Cost

| Scenario | Monthly Cost |
|---|---|
| Always-on, defaults only | ~$80–$100 |
| Stop nights & weekends | ~$55–$75 |
| All toggles ON excl. Firewall | ~$105–$130 |
| All toggles ON incl. Firewall | ~$1,000+ |

## Quick Start

### Prerequisites

- Azure Subscription (Contributor role)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- [PowerShell](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
- [Git](https://git-scm.com/)

Or use the **Dev Container** for a one-click setup:

[![Open in Dev Container](https://img.shields.io/static/v1?label=Dev%20Container&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/Jamonygr/aks-landing-zone-lab)

### 1. Bootstrap

```powershell
# Clone the repo
git clone https://github.com/Jamonygr/aks-landing-zone-lab.git
cd aks-landing-zone-lab

# Install prereqs & create state backend
.\scripts\bootstrap.ps1
```

### 2. Deploy Infrastructure

```powershell
# Deploy with dev defaults (~$80-100/mo)
.\scripts\deploy.ps1 -Environment dev

# Or use lab environment (more features, ~$105-130/mo)
.\scripts\deploy.ps1 -Environment lab
```

### 3. Connect to Cluster

```powershell
.\scripts\get-credentials.ps1 -Environment dev
kubectl get nodes
```

### 4. Deploy Workloads

```powershell
.\scripts\deploy-workloads.ps1
```

### 5. Save Money

```powershell
# Stop cluster when not in use
.\scripts\stop-lab.ps1 -Environment dev

# Start it back up
.\scripts\start-lab.ps1 -Environment dev

# Check your spending
.\scripts\cost-check.ps1
```

## Repository Structure

```
├── landing-zones/              # Azure Landing Zone pattern
│   ├── networking/             # Hub-spoke VNets, NSGs, peering, firewall
│   ├── aks-platform/           # AKS cluster, ACR, ingress, DNS
│   ├── management/             # Log Analytics, alerts, Prometheus, Grafana
│   ├── security/               # Key Vault, policies, Defender
│   ├── governance/             # Custom policies, compliance
│   └── identity/               # Workload identity, managed identities
├── modules/                    # Reusable Terraform modules
│   ├── networking/             # vnet, subnet, nsg, route-table, peering, dns
│   ├── aks/                    # AKS cluster module
│   ├── acr/                    # Container registry module
│   ├── firewall/               # Azure Firewall module
│   ├── keyvault/               # Key Vault module
│   ├── monitoring/             # log-analytics, alerts, diagnostics, action-group
│   ├── ingress/                # NGINX ingress controller
│   ├── policy/                 # Azure Policy assignments
│   ├── rbac/                   # Role assignments
│   ├── cost-management/        # Budget alerts
│   ├── naming/                 # Naming convention generator
│   ├── resource-group/         # Resource group module
│   └── storage/                # Storage account module
├── k8s/                        # Kubernetes manifests
│   ├── namespaces/             # Namespaces, quotas, RBAC
│   ├── apps/                   # 13 sample workloads
│   ├── security/               # Network policies, PSA labels
│   ├── autoscaling/            # HPA, KEDA, load tests
│   ├── storage/                # StorageClasses
│   ├── monitoring/             # Prometheus scrape configs
│   ├── chaos/                  # Chaos Mesh experiments
│   ├── backup/                 # Velero schedules
│   └── gitops/                 # Flux v2 sources & kustomizations
├── environments/               # Per-environment tfvars
│   ├── dev.tfvars              # Budget-safe defaults
│   ├── lab.tfvars              # Extended features
│   └── prod.tfvars             # All features (reference)
├── scripts/                    # Operational PowerShell scripts
├── docs/                       # Lab guides & documentation
├── wiki/                       # Detailed wiki pages
├── .github/workflows/          # CI/CD pipeline
├── .devcontainer/              # VS Code Dev Container
├── main.tf                     # Root module
├── providers.tf                # Provider configuration
├── backend.tf                  # Remote state backend
├── variables.tf                # Input variables
├── locals.tf                   # Naming & computed values
├── outputs.tf                  # Outputs
└── lab-plan.txt                # Full 156-element lab plan
```

## What's Included (156 Elements)

| Category | Count | Key Components |
|---|---|---|
| Prerequisites & Tooling | 7 | Azure CLI, Terraform, kubectl, helm |
| Terraform Foundation | 7 | Providers, backend, variables, locals |
| Hub Network | 10 | VNet, subnets, NSGs, firewall (optional) |
| Spoke Network (AKS) | 8 | VNet, AKS subnets, ingress subnet |
| VNet Peering | 2 | Bidirectional hub↔spoke |
| AKS Cluster | 8 | Managed identity, CNI Overlay, Calico |
| Container Registry | 3 | ACR Basic, AcrPull role |
| Ingress & DNS | 4 | NGINX, public IP, DNS (optional) |
| Monitoring Core | 5 | Log Analytics, Container Insights |
| Monitoring Advanced | 7 | Prometheus, Grafana (optional) |
| Alerts | 11 | Node, pod, API, budget alerts |
| Security | 6 | Policy, Defender, Key Vault, CSI |
| Namespaces & RBAC | 7 | 4 namespaces, quotas, limits |
| Sample Workloads | 13 | hello-web, stress, chaos, metrics |
| Autoscaling | 4 | HPA, cluster autoscaler, KEDA |
| Storage | 3 | Disk + Files StorageClasses |
| GitOps | 4 | Flux v2, auto-sync |
| Chaos Engineering | 4 | Chaos Mesh, experiments |
| Cost Management | 3 | Kubecost, stop/start scripts |
| Backup & DR | 3 | Velero, scheduled backups |
| Identity | 2 | Workload Identity Federation |
| Advanced Networking | 3 | Private DNS, Network Watcher |
| Developer Experience | 2 | Dev Container, Bridge to K8s |
| Governance | 4 | Custom policies, compliance |
| Observability Extras | 3 | kube-state-metrics, SLO dashboards |
| Operational Scripts | 9 | Bootstrap, deploy, destroy, cost |
| Documentation | 9 | Lab guide, architecture, security |
| CI/CD | 3 | GitHub Actions, pre-commit |

## Optional Toggles

All expensive features are **OFF by default** to keep costs low:

| Toggle | Cost if ON | Variable |
|---|---|---|
| Azure Firewall (Basic) | +$900/mo | `enable_firewall` |
| Managed Grafana | +$10/mo | `enable_managed_grafana` |
| Managed Prometheus | +$0–5/mo | `enable_managed_prometheus` |
| Defender for Containers | +$7/node/mo | `enable_defender` |
| Azure DNS Zone | +$0.50/mo | `enable_dns_zone` |
| KEDA | Free | `enable_keda` |
| Azure Files StorageClass | ~$1/mo | `enable_azure_files` |

## Documentation

| Guide | Description |
|---|---|
| [Lab Guide](docs/lab-guide.md) | Step-by-step exercises (Day 1 → Day 8) |
| [Architecture](docs/architecture.md) | Hub-spoke diagram, IP plan, traffic flows |
| [Monitoring Guide](docs/monitoring-guide.md) | KQL queries, dashboards, alert testing |
| [Security Guide](docs/security-guide.md) | Policies, network policies, Key Vault |
| [Cost Optimization](docs/cost-optimization.md) | Stay under budget, teardown reminders |
| [Troubleshooting](docs/troubleshooting.md) | Common errors & fixes |
| [Chaos Guide](docs/chaos-guide.md) | Chaos experiments & recovery procedures |
| [GitOps Guide](docs/gitops-guide.md) | Flux setup & workflow |

## License

MIT

---

*Built with ❤️ for learning AKS the enterprise way.*
