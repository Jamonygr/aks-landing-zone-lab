#Requires -Version 5.1
<#
.SYNOPSIS
    Get AKS cluster credentials and verify connectivity.

.DESCRIPTION
    Retrieves kubeconfig credentials for the specified AKS cluster, tests
    the kubectl connection, and prints cluster info.

.PARAMETER Environment
    Target environment (dev, lab, prod, staging). Default: dev.

.PARAMETER ClusterName
    AKS cluster name. If omitted, derived from environment: aks-akslab-<env>.

.PARAMETER ResourceGroup
    Resource group containing the cluster. If omitted, derived from environment:
    rg-spoke-aks-networking-<env>.

.PARAMETER Admin
    Get admin credentials instead of user credentials.

.EXAMPLE
    .\scripts\get-credentials.ps1 -Environment dev

.EXAMPLE
    .\scripts\get-credentials.ps1 -ClusterName aks-akslab-lab -ResourceGroup rg-spoke-aks-akslab-lab

.EXAMPLE
    .\scripts\get-credentials.ps1 -Environment prod -Admin
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("dev", "lab", "prod", "staging")]
    [string]$Environment = "dev",

    [Parameter()]
    [string]$ClusterName,

    [Parameter()]
    [string]$ResourceGroup,

    [Parameter()]
    [switch]$Admin
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN]    $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR]   $Msg" -ForegroundColor Red }

# ── Derive defaults ─────────────────────────────────────────────────────────

$projectName = "akslab"

if (-not $ClusterName) {
    $ClusterName = "aks-${projectName}-${Environment}"
}
if (-not $ResourceGroup) {
    $ResourceGroup = "rg-spoke-aks-networking-${Environment}"
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          AKS Landing Zone Lab - Get Credentials             ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Info "Cluster:        $ClusterName"
Write-Info "Resource Group: $ResourceGroup"
Write-Info "Admin mode:     $($Admin.IsPresent)"
Write-Host ""

# ── Verify cluster exists ───────────────────────────────────────────────────

Write-Info "Verifying cluster exists..."
try {
    $clusterInfo = az aks show --name $ClusterName --resource-group $ResourceGroup --output json 2>$null | ConvertFrom-Json
    if (-not $clusterInfo) {
        Write-Err "Cluster '$ClusterName' not found in resource group '$ResourceGroup'."
        exit 1
    }
    Write-Success "Cluster found. Power state: $($clusterInfo.powerState.code)"
} catch {
    Write-Err "Failed to query cluster: $_"
    Write-Warn "Make sure you are logged in (az login) and the cluster exists."
    exit 1
}

if ($clusterInfo.powerState.code -eq "Stopped") {
    Write-Warn "Cluster is currently STOPPED. Start it first:"
    Write-Warn "  .\scripts\start-lab.ps1 -Environment $Environment"
    exit 1
}

# ── Get credentials ──────────────────────────────────────────────────────────

Write-Info "Fetching kubeconfig..."

$credArgs = @(
    "aks", "get-credentials",
    "--resource-group", $ResourceGroup,
    "--name", $ClusterName,
    "--overwrite-existing"
)

if ($Admin) {
    $credArgs += "--admin"
}

az @credArgs
if ($LASTEXITCODE -ne 0) {
    Write-Err "Failed to get credentials."
    exit 1
}

Write-Success "Kubeconfig merged for cluster '$ClusterName'."
Write-Host ""

# ── Test connection ──────────────────────────────────────────────────────────

Write-Info "Testing kubectl connection..."

try {
    $nodes = kubectl get nodes --output json 2>$null | ConvertFrom-Json
    if (-not $nodes -or $nodes.items.Count -eq 0) {
        Write-Warn "Connected but no nodes found. Cluster may be scaling up."
    } else {
        Write-Success "Connected. Found $($nodes.items.Count) node(s)."
        Write-Host ""
        Write-Host "  Nodes:" -ForegroundColor White
        foreach ($node in $nodes.items) {
            $name   = $node.metadata.name
            $status = ($node.status.conditions | Where-Object { $_.type -eq "Ready" }).status
            $ver    = $node.status.nodeInfo.kubeletVersion
            $color  = if ($status -eq "True") { "Green" } else { "Yellow" }
            Write-Host "    $name  " -NoNewline -ForegroundColor White
            Write-Host "Ready=$status  " -NoNewline -ForegroundColor $color
            Write-Host "v$ver" -ForegroundColor White
        }
    }
} catch {
    Write-Warn "kubectl connection test failed: $_"
    Write-Warn "The cluster may still be starting up. Try again in a moment."
}

# ── Cluster info summary ────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          Cluster Info                                        ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Cluster Name:      $ClusterName" -ForegroundColor White
Write-Host "  Resource Group:    $ResourceGroup" -ForegroundColor White
Write-Host "  Location:          $($clusterInfo.location)" -ForegroundColor White
Write-Host "  K8s Version:       $($clusterInfo.kubernetesVersion)" -ForegroundColor White
Write-Host "  FQDN:              $($clusterInfo.fqdn)" -ForegroundColor White
Write-Host "  Power State:       $($clusterInfo.powerState.code)" -ForegroundColor White
Write-Host "  Provisioning:      $($clusterInfo.provisioningState)" -ForegroundColor White
Write-Host "  Network Plugin:    $($clusterInfo.networkProfile.networkPlugin)" -ForegroundColor White
Write-Host ""

# Print namespaces
try {
    Write-Info "Namespaces:"
    $namespaces = kubectl get namespaces --output json 2>$null | ConvertFrom-Json
    foreach ($ns in $namespaces.items) {
        $nsName   = $ns.metadata.name
        $nsStatus = $ns.status.phase
        Write-Host "    $nsName ($nsStatus)" -ForegroundColor White
    }
} catch {
    Write-Warn "Could not list namespaces."
}

Write-Host ""
Write-Info "Current context: $(kubectl config current-context 2>$null)"
Write-Info "Next step:  .\scripts\deploy-workloads.ps1"
Write-Host ""
