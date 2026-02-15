<p align="center">
  <img src="docs/images/hero.svg" alt="AKS Landing Zone Lab" width="800"/>
</p>

<h1 align="center">AKS Landing Zone Lab</h1>

<p align="center">
  <strong>Enterprise-grade Azure Kubernetes Service environment built with Terraform modular landing zones</strong>
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/Terraform-%3E%3D1.5-844fba?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"></a>
  <a href="#"><img src="https://img.shields.io/badge/AzureRM-~%3E4.0-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white" alt="AzureRM"></a>
  <a href="#"><img src="https://img.shields.io/badge/Kubernetes-1.32-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes"></a>
  <a href="#"><img src="https://img.shields.io/badge/PowerShell-Scripts-012456?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"></a>
</p>

---

## Overview

A fully modular AKS landing zone designed for **learning**, **lab exercises**, and **production-readiness exploration**. Deploys a hub-spoke network topology with six landing zone modules — each encapsulating a distinct operational concern following [Azure Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/) patterns.

### What You Get

| Component | Details |
|-----------|---------|
| **Networking** | Hub-spoke VNet topology with peering, NSGs, route tables, optional Azure Firewall |
| **AKS Platform** | Managed Kubernetes with system/user node pools, autoscaling, Azure CNI Overlay, Calico network policy |
| **Ingress** | NGINX Ingress Controller with static public IP via Helm |
| **Container Registry** | Azure Container Registry with `AcrPull` role assignment to AKS |
| **Monitoring** | Log Analytics, Container Insights, Prometheus, Grafana, 6 alert rules |
| **Security** | Key Vault with CSI driver, Pod Security Baseline policy, optional Defender for Containers |
| **Governance** | Custom Azure Policy (resource limits enforcement, ACR image restriction) |
| **Identity** | Workload Identity federation with managed identities and OIDC |

---

## Architecture

<p align="center">
  <img src="docs/images/architecture-overview.svg" alt="Architecture Overview" width="850"/>
</p>

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Hub VNet (10.0.0.0/16)                        │
│  ┌──────────────┐  ┌──────────────────┐  ┌───────────────────────────┐ │
│  │  Management  │  │ Shared Services  │  │  AzureFirewallSubnet      │ │
│  │  10.0.1.0/24 │  │  10.0.2.0/24     │  │  10.0.3.0/24 (optional)  │ │
│  └──────────────┘  └──────────────────┘  └───────────────────────────┘ │
└────────────────────────────┬────────────────────────────────────────────┘
                             │ VNet Peering (bidirectional)
┌────────────────────────────┴────────────────────────────────────────────┐
│                       Spoke VNet (10.1.0.0/16)                         │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────────────────┐  │
│  │  AKS System    │  │  AKS User      │  │  Ingress                 │  │
│  │  10.1.0.0/20   │  │  10.1.16.0/20  │  │  10.1.32.0/24            │  │
│  └───────┬────────┘  └───────┬────────┘  └──────────┬───────────────┘  │
│          │                   │                      │                  │
│          └───────────────────┼──────────────────────┘                  │
│                              │                                         │
│                   ┌──────────┴──────────┐                              │
│                   │    AKS Cluster      │                              │
│                   │  ┌───────────────┐  │                              │
│                   │  │ System Pool   │  │  Azure CNI Overlay           │
│                   │  │ User Pool     │  │  Pod CIDR: 192.168.0.0/16   │
│                   │  │ NGINX Ingress │  │  Svc CIDR: 172.16.0.0/16    │
│                   │  └───────────────┘  │                              │
│                   └─────────────────────┘                              │
└────────────────────────────────────────────────────────────────────────┘
```

### Deployment Flow

<p align="center">
  <img src="docs/images/deployment-flow.svg" alt="Deployment Flow" width="750"/>
</p>

---

## Landing Zone Modules

Each landing zone is an independent Terraform module under `landing-zones/`:

```
landing-zones/
├── networking/       # Hub-spoke VNets, subnets, NSGs, route tables, peering, firewall
├── aks-platform/     # AKS cluster, node pools, ACR, NGINX ingress, DNS
├── management/       # Log Analytics, Prometheus, Grafana, alerts, budgets
├── security/         # Key Vault, CSI Secrets Store, Pod Security, Defender
├── governance/       # Custom Azure Policy definitions & assignments
└── identity/         # Workload Identity, managed identities, OIDC federation
```

| Module | Resources Created | Key Features |
|--------|-------------------|-------------|
| **Networking** | 2 VNets, 6 subnets, 3 NSGs, route table, peering | Hub-spoke topology, optional firewall |
| **AKS Platform** | AKS cluster, 2 node pools, ACR, public IP, DNS | Autoscaling, Azure RBAC, OIDC |
| **Management** | Log Analytics, Prometheus, Grafana, 6 alert rules, budget | Container Insights, cost control |
| **Security** | Key Vault, CSI driver (Helm), Pod Security policy | Secrets management, baseline policies |
| **Governance** | 2 custom policies, 2 assignments | Resource limits, ACR image enforcement |
| **Identity** | Managed identity, federated credential | Workload Identity for pods |

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| **Azure CLI** | 2.x+ | [Install](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| **Terraform** | >= 1.5 | [Install](https://developer.hashicorp.com/terraform/install) |
| **kubectl** | 1.29+ | `az aks install-cli` |
| **Helm** | 3.x+ | [Install](https://helm.sh/docs/intro/install/) |
| **PowerShell** | 5.1+ / 7.x | Built-in on Windows |
| **Git** | 2.x+ | [Install](https://git-scm.com/downloads) |

**Azure requirements:**
- Active Azure subscription with **Contributor** role
- Resource providers registered: `Microsoft.ContainerService`, `Microsoft.Monitor`, `Microsoft.Dashboard`

---

## Quick Start

### 1. Clone & Bootstrap

```powershell
git clone https://github.com/Jamonygr/AKS.git
cd AKS

# Install prerequisites, create Terraform state backend
.\scripts\bootstrap.ps1 -SubscriptionId "<your-subscription-id>"
```

### 2. Deploy Infrastructure

```powershell
# Deploy the dev environment (~$80-100/mo)
.\scripts\deploy.ps1 -Environment dev

# Or use Terraform directly
terraform init
terraform plan  -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

### 3. Connect to Cluster

```powershell
.\scripts\get-credentials.ps1 -Environment dev
kubectl get nodes
```

### 4. Deploy Workloads

```powershell
.\scripts\deploy-workloads.ps1
kubectl get pods -A
```

### 5. Stop / Start (Save Costs)

```powershell
.\scripts\stop-lab.ps1  -Environment dev   # Deallocate nodes
.\scripts\start-lab.ps1 -Environment dev   # Bring back up
.\scripts\cost-check.ps1 -Environment dev  # Check spending
```

### 6. Tear Down

```powershell
.\scripts\cleanup-workloads.ps1
.\scripts\destroy.ps1 -Environment dev
```

---

## Environment Profiles

Three pre-configured environments with different cost/feature trade-offs:

| Environment | File | Monthly Cost | Features Enabled | Use Case |
|-------------|------|-------------|------------------|----------|
| **dev** | `environments/dev.tfvars` | ~$80–100 | Cluster alerts only | Daily learning, minimal cost |
| **lab** | `environments/lab.tfvars` | ~$105–130 | Prometheus, Grafana, KEDA, DNS, Azure Files | Feature exploration, labs |
| **prod** | `environments/prod.tfvars` | ~$1,000+ | Everything incl. Firewall & Defender | Reference architecture |

> **Tip:** Use `dev` for day-to-day learning. Use `lab` when exploring monitoring and autoscaling. The `prod` profile is a reference — not recommended for learning due to cost.

### Feature Toggle Matrix

| Feature | Dev | Lab | Prod | Monthly Cost |
|---------|-----|-----|------|-------------|
| Cluster Alerts | ✅ | ✅ | ✅ | Free |
| Managed Prometheus | ❌ | ✅ | ✅ | ~$0–5 |
| Managed Grafana | ❌ | ✅ | ✅ | ~$10 |
| DNS Zone | ❌ | ✅ | ✅ | ~$0.50 |
| KEDA Autoscaling | ❌ | ✅ | ✅ | Free |
| Azure Files Storage | ❌ | ✅ | ✅ | ~$1 |
| Defender for Containers | ❌ | ❌ | ✅ | ~$7/node |
| Azure Firewall | ❌ | ❌ | ✅ | ~$900 |
| App Insights | ❌ | ❌ | ✅ | ~$0–5 |

---

## Kubernetes Manifests

Ready-to-deploy manifests organized by concern in `k8s/`:

```
k8s/
├── namespaces/       # Namespace definitions, RBAC, resource quotas, limit ranges
├── security/         # Network policies, pod security admission
├── storage/          # Azure Disk and Azure Files storage classes
├── apps/             # Sample applications
│   ├── hello-web.yaml           # Simple web server
│   ├── metrics-app.yaml         # App exposing Prometheus metrics
│   ├── log-generator.yaml       # Generates sample log output
│   ├── crashloop-pod.yaml       # For troubleshooting practice
│   ├── stress-cpu.yaml          # CPU stress for autoscaling tests
│   ├── stress-memory.yaml       # Memory stress for OOM tests
│   ├── multi-container.yaml     # Sidecar pattern example
│   ├── config-consumer.yaml     # ConfigMap consumption
│   ├── secret-consumer.yaml     # Secret consumption
│   ├── network-policy-test.yaml # Network policy validation
│   ├── pv-test.yaml             # Persistent volume test
│   └── ...
├── monitoring/       # Prometheus scrape configuration
├── autoscaling/      # HPA, KEDA ScaledObject, load test jobs
├── chaos/            # Chaos Mesh experiments (pod kill, network delay)
├── gitops/           # Flux source, kustomization, notification
└── backup/           # Velero backup schedule
```

---

## Operational Scripts

All scripts are in `scripts/` and accept `-Environment` (dev/lab/prod):

| Script | Purpose |
|--------|---------|
| `bootstrap.ps1` | Install prerequisites, create Terraform remote state backend |
| `deploy.ps1` | Run `terraform init`, `plan`, and `apply` for an environment |
| `get-credentials.ps1` | Fetch kubeconfig and verify cluster connectivity |
| `deploy-workloads.ps1` | Apply K8s manifests in dependency order |
| `cleanup-workloads.ps1` | Remove K8s manifests in reverse order |
| `stop-lab.ps1` | Deallocate AKS cluster (save costs) |
| `start-lab.ps1` | Start a stopped AKS cluster |
| `cost-check.ps1` | Query Azure Cost Management and compare against budget |
| `destroy.ps1` | Run `terraform destroy` and check for orphaned resources |

---

## Repository Structure

```
AKS/
├── main.tf                    # Root module — wires all landing zones together
├── variables.tf               # Input variables with validation
├── locals.tf                  # Naming conventions, tags, CIDR calculations
├── outputs.tf                 # Cluster info, endpoints, connection commands
├── providers.tf               # AzureRM ~>4.0, Helm ~>2.12
├── backend.tf                 # Azure Storage remote state
├── terraform.tfvars.example   # Sample variable values
│
├── environments/              # Per-environment variable files
│   ├── dev.tfvars
│   ├── lab.tfvars
│   └── prod.tfvars
│
├── landing-zones/             # Core infrastructure modules
│   ├── networking/
│   ├── aks-platform/
│   ├── management/
│   ├── security/
│   ├── governance/
│   └── identity/
│
├── modules/                   # Reusable child modules
│   ├── acr/
│   ├── aks/
│   ├── cost-management/
│   ├── firewall/
│   ├── keyvault/
│   ├── monitoring/
│   ├── networking/
│   ├── policy/
│   ├── rbac/
│   ├── resource-group/
│   └── storage/
│
├── k8s/                       # Kubernetes manifests
│   ├── apps/
│   ├── autoscaling/
│   ├── backup/
│   ├── chaos/
│   ├── gitops/
│   ├── monitoring/
│   ├── namespaces/
│   ├── security/
│   └── storage/
│
├── scripts/                   # PowerShell automation
│   ├── bootstrap.ps1
│   ├── deploy.ps1
│   ├── deploy-workloads.ps1
│   ├── get-credentials.ps1
│   ├── stop-lab.ps1
│   ├── start-lab.ps1
│   ├── cost-check.ps1
│   ├── cleanup-workloads.ps1
│   └── destroy.ps1
│
├── docs/                      # Guides and references
│   ├── architecture.md
│   ├── lab-guide.md
│   ├── monitoring-guide.md
│   ├── security-guide.md
│   ├── cost-optimization.md
│   ├── chaos-guide.md
│   ├── gitops-guide.md
│   └── troubleshooting.md
│
└── wiki/                      # Extended documentation
    ├── architecture/
    ├── landing-zones/
    ├── modules/
    └── reference/
```

---

## Terraform Usage

### Initialize & Plan

```powershell
terraform init
terraform plan -var-file="environments/dev.tfvars"
```

### Apply

```powershell
terraform apply -var-file="environments/dev.tfvars"
```

### Key Outputs

```powershell
terraform output cluster_name          # AKS cluster name
terraform output cluster_fqdn          # API server FQDN
terraform output kubeconfig_command     # az aks get-credentials command
terraform output acr_login_server      # ACR login URL
terraform output ingress_public_ip     # NGINX Ingress public IP
terraform output grafana_endpoint      # Grafana dashboard URL (if enabled)
```

### Destroy

```powershell
terraform destroy -var-file="environments/dev.tfvars"
```

---

## Network Design

| Network | CIDR | Purpose |
|---------|------|---------|
| Hub VNet | `10.0.0.0/16` | Shared services, management, firewall |
| Spoke VNet | `10.1.0.0/16` | AKS workloads |
| Pod CIDR | `192.168.0.0/16` | Azure CNI Overlay pod addresses |
| Service CIDR | `172.16.0.0/16` | Kubernetes service ClusterIPs |
| DNS Service IP | `172.16.0.10` | CoreDNS |

### Subnet Allocation

| Subnet | CIDR | VNet | NSG |
|--------|------|------|-----|
| Management | `10.0.1.0/24` | Hub | — |
| Shared Services | `10.0.2.0/24` | Hub | — |
| AzureFirewallSubnet | `10.0.3.0/24` | Hub | — |
| AKS System Pool | `10.1.0.0/20` | Spoke | `nsg-aks-system` |
| AKS User Pool | `10.1.16.0/20` | Spoke | `nsg-aks-user` |
| Ingress | `10.1.32.0/24` | Spoke | `nsg-ingress` |

---

## Monitoring & Alerting

When enabled, the management landing zone deploys:

- **Log Analytics Workspace** — 30-day retention, Container Insights solution
- **Azure Managed Prometheus** — metrics collection via data collection rules
- **Azure Managed Grafana v11** — dashboards linked to Prometheus
- **6 Scheduled Query Alert Rules:**

| Alert | Severity | Trigger |
|-------|----------|---------|
| Failed Pods | Sev 2 | Pods in Failed phase |
| Pod Restarts | Sev 2 | Containers restarting frequently |
| Image Pull Failure | Sev 2 | `ErrImagePull` / `ImagePullBackOff` |
| OOMKilled | Sev 2 | Containers killed by OOM |
| API Server 5xx | Sev 1 | 5xx errors from API server |
| Log Ingestion Cap | Sev 2 | Daily ingestion exceeds threshold |

---

## Security Features

- **Azure RBAC for Kubernetes** — AAD-integrated authorization
- **Pod Security Baseline** — Azure Policy in Audit mode
- **Custom Policies** — Enforce resource limits, restrict container images to ACR
- **Key Vault + CSI Driver** — Mount secrets as volumes in pods
- **Calico Network Policies** — Fine-grained pod traffic control
- **Workload Identity** — Keyless Azure authentication from pods via OIDC federation
- **Managed Identity** — No service principal credentials stored

---

## Cost Management

- **Budget alerts** at 80% and 100% thresholds per environment
- **Stop/start scripts** to deallocate clusters when not in use
- **`cost-check.ps1`** queries Azure Cost Management API in real time
- **Feature toggles** let you enable only what you need

Estimated monthly costs:

| Profile | Always-On | With Stop/Start |
|---------|-----------|-----------------|
| Dev | ~$80–100 | ~$55–75 |
| Lab | ~$105–130 | ~$75–95 |
| Prod | ~$1,000+ | N/A |

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Lab Guide](docs/lab-guide.md) | 8-day structured learning path |
| [Architecture](docs/architecture.md) | Design decisions and patterns |
| [Monitoring Guide](docs/monitoring-guide.md) | Prometheus, Grafana, alerting setup |
| [Security Guide](docs/security-guide.md) | RBAC, policies, secrets management |
| [Cost Optimization](docs/cost-optimization.md) | Tips to minimize Azure spend |
| [Chaos Engineering](docs/chaos-guide.md) | Chaos Mesh experiments |
| [GitOps Guide](docs/gitops-guide.md) | Flux CD integration |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and fixes |

---

## Lab Guide Overview

The [lab guide](docs/lab-guide.md) provides an 8-day structured curriculum:

| Day | Topic | What You'll Do |
|-----|-------|---------------|
| 1 | Bootstrap & Deploy | Set up prerequisites, deploy infrastructure |
| 2 | Cluster Operations | Explore nodes, pods, namespaces, kubectl |
| 3 | Networking | VNet peering, NSGs, ingress, network policies |
| 4 | Workloads | Deploy apps, configure storage, manage secrets |
| 5 | Monitoring | Set up dashboards, alerts, log queries |
| 6 | Security | RBAC, pod security, Key Vault integration |
| 7 | Autoscaling & Chaos | HPA, KEDA, Chaos Mesh experiments |
| 8 | Cleanup & Review | Cost analysis, teardown, lessons learned |

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-change`
3. Make changes and test with `terraform validate` and `terraform fmt -check -recursive`
4. Submit a pull request

---

## License

This project is licensed under the [MIT License](LICENSE).
