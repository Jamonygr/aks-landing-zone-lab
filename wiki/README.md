<div align="center">

# 📘 AKS Landing Zone Lab — Wiki

**Enterprise-grade AKS infrastructure on Azure using Terraform landing zones**

[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.32-326CE5?style=flat-square&logo=kubernetes&logoColor=white)](#)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-844fba?style=flat-square&logo=terraform&logoColor=white)](#)
[![AzureRM](https://img.shields.io/badge/AzureRM-~%3E4.0-0078D4?style=flat-square&logo=microsoftazure&logoColor=white)](#)

---

</div>

## 🗺 Navigation

<table>
<tr>
<td width="50%" valign="top">

### 🏁 Getting Started
| | Guide | Description |
|:--|:------|:------------|
| 📘 | [Lab Guide](guides/lab-guide.md) | 8-day structured curriculum |
| 💰 | [Cost Optimization](guides/cost-optimization.md) | Budget management and teardown |
| 🔧 | [Troubleshooting](guides/troubleshooting.md) | Common errors and fixes |

### 🏛 Architecture
| | Page | Description |
|:--|:-----|:------------|
| 🔭 | [Architecture Overview](architecture/overview.md) | Design philosophy and components |
| 🌐 | [Network Topology](architecture/network-topology.md) | Hub-spoke design, IP plan, NSGs |
| 🔐 | [Security Model](architecture/security-model.md) | Defense-in-depth, 6 security layers |

</td>
<td width="50%" valign="top">

### 🏗 Infrastructure
| | Page | Description |
|:--|:-----|:------------|
| 🧩 | [Landing Zones](landing-zones/README.md) | 6 landing zone modules |
| 📦 | [Module Index](modules/README.md) | All reusable Terraform modules |

### 📖 Reference
| | Page | Description |
|:--|:-----|:------------|
| 🏷 | [Naming Conventions](reference/naming-conventions.md) | Resource naming standards |
| ⚙ | [Variables Reference](reference/variables.md) | All Terraform input variables |
| 📤 | [Outputs Reference](reference/outputs.md) | All Terraform outputs |

### 📚 Guides
| | Guide | Description |
|:--|:------|:------------|
| 📊 | [Monitoring Guide](guides/monitoring-guide.md) | Log Analytics, KQL, Insights |
| 🔒 | [Security Guide](guides/security-guide.md) | Network policies, PSA, Key Vault |
| 💥 | [Chaos Guide](guides/chaos-guide.md) | Chaos Mesh experiments |
| 🔄 | [GitOps Guide](guides/gitops-guide.md) | Flux v2 setup and workflow |

</td>
</tr>
</table>

---

## 📂 Project Structure

```
aks-landing-zone-lab/
│
├── main.tf                        Root module — orchestrates all landing zones
├── variables.tf                   All input variables
├── outputs.tf                     Cluster info, endpoints, kubeconfig
├── locals.tf                      Naming, tags, computed values
├── backend.tf                     Azure Storage remote state
├── providers.tf                   azurerm, azuread, helm, kubernetes
│
├── environments/                  Per-environment variable files
│   ├── dev.tfvars                   Budget-safe defaults (~$5/day)
│   ├── lab.tfvars                   Extended features (~$8/day)
│   └── prod.tfvars                  Production reference profile
│
├── landing-zones/                 6 landing zone modules
│   ├── networking/                  Hub-spoke VNets, peering, NSGs
│   ├── aks-platform/                AKS cluster, ACR, ingress
│   ├── management/                  Log Analytics, alerts, budgets
│   ├── security/                    Key Vault, policies, Defender
│   ├── governance/                  Custom Azure Policies
│   └── identity/                    Workload Identity, managed IDs
│
├── modules/                       14 reusable Terraform modules
│
├── k8s/                           Kubernetes manifests
│   ├── namespaces/                  Namespace defs, quotas, RBAC
│   ├── apps/                        13 sample workloads
│   ├── security/                    Network policies, PSA
│   ├── autoscaling/                 HPA, KEDA, load tests
│   ├── storage/                     StorageClasses
│   ├── monitoring/                  Prometheus scrape configs
│   ├── chaos/                       Chaos Mesh experiments
│   ├── backup/                      Velero schedules
│   └── gitops/                      Flux v2 configuration
│
├── scripts/                       PowerShell operational scripts
└── wiki/                          Documentation (you are here)
    ├── guides/                    Lab, monitoring, security guides
    ├── images/                    SVG diagrams and images
    ├── architecture/              Architecture deep-dives
    ├── landing-zones/             Landing zone details
    ├── modules/                   Module index
    └── reference/                 Variables, outputs, naming
```

---

## 🌍 Environment Comparison

<table>
<tr>
<th></th>
<th align="center">🧪 Dev</th>
<th align="center">🔬 Lab</th>
<th align="center">🏭 Prod</th>
</tr>
<tr><td><b>Est. Cost</b></td><td align="center">~$5/day</td><td align="center">~$8/day</td><td align="center">~$25/day</td></tr>
<tr><td><b>Prometheus</b></td><td align="center">❌</td><td align="center">✅</td><td align="center">✅</td></tr>
<tr><td><b>Grafana</b></td><td align="center">❌</td><td align="center">✅</td><td align="center">✅</td></tr>
<tr><td><b>Defender</b></td><td align="center">❌</td><td align="center">❌</td><td align="center">✅</td></tr>
<tr><td><b>KEDA</b></td><td align="center">❌</td><td align="center">✅</td><td align="center">✅</td></tr>
<tr><td><b>DNS Zone</b></td><td align="center">❌</td><td align="center">✅</td><td align="center">✅</td></tr>
<tr><td><b>Azure Files</b></td><td align="center">❌</td><td align="center">✅</td><td align="center">✅</td></tr>
<tr><td><b>Firewall</b></td><td align="center">❌</td><td align="center">❌</td><td align="center">✅</td></tr>
</table>

---

## 🤝 Contributing

1. Create a feature branch from `main`
2. Make changes and test with `terraform plan -var-file="environments/dev.tfvars"`
3. Submit a pull request
4. CI runs `terraform fmt -check`, `terraform validate`, and `terraform plan`

---

<div align="center">

**[⬆ Back to Top](#)**

</div>
