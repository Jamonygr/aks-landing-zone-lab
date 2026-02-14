#Requires -Version 5.1
<#
.SYNOPSIS
    Stop the AKS lab cluster to save costs.

.DESCRIPTION
    Stops the AKS cluster using 'az aks stop'. While stopped, the control
    plane and nodes are deallocated and you are only charged for storage.
    Prints estimated savings.

.PARAMETER Environment
    Target environment (dev, lab, prod). Default: dev.

.PARAMETER ClusterName
    AKS cluster name. If omitted, derived from environment.

.PARAMETER ResourceGroup
    Resource group containing the cluster. If omitted, derived from environment.

.EXAMPLE
    .\scripts\stop-lab.ps1

.EXAMPLE
    .\scripts\stop-lab.ps1 -Environment lab
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("dev", "lab", "prod")]
    [string]$Environment = "dev",

    [Parameter()]
    [string]$ClusterName,

    [Parameter()]
    [string]$ResourceGroup
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
    $ResourceGroup = "rg-spoke-aks-${projectName}-${Environment}"
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          AKS Landing Zone Lab - Stop Cluster                ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Info "Cluster:        $ClusterName"
Write-Info "Resource Group: $ResourceGroup"
Write-Host ""

# ── Check current state ─────────────────────────────────────────────────────

Write-Info "Checking cluster status..."

try {
    $clusterInfo = az aks show --name $ClusterName --resource-group $ResourceGroup --output json 2>$null | ConvertFrom-Json
    if (-not $clusterInfo) {
        Write-Err "Cluster '$ClusterName' not found in resource group '$ResourceGroup'."
        exit 1
    }
} catch {
    Write-Err "Failed to query cluster: $_"
    exit 1
}

$currentState = $clusterInfo.powerState.code

if ($currentState -eq "Stopped") {
    Write-Success "Cluster is already stopped."
    Write-Info "No action needed."
    exit 0
}

Write-Info "Current power state: $currentState"

# ── Count nodes for savings estimate ─────────────────────────────────────────

$nodeCount = 0
foreach ($pool in $clusterInfo.agentPoolProfiles) {
    $nodeCount += $pool.count
}

$vmSize = $clusterInfo.agentPoolProfiles[0].vmSize
Write-Info "Node count: $nodeCount ($vmSize)"

# Rough hourly cost estimates for common VM sizes
$hourlyCostEstimate = switch -Wildcard ($vmSize) {
    "Standard_B2s"   { 0.0416 }
    "Standard_B2ms"  { 0.0832 }
    "Standard_B4ms"  { 0.166  }
    "Standard_D2s*"  { 0.096  }
    "Standard_D4s*"  { 0.192  }
    "Standard_D2as*" { 0.096  }
    default          { 0.10   }
}

$dailySavings   = $hourlyCostEstimate * $nodeCount * 24
$monthlySavings = $dailySavings * 30

# ── Stop cluster ────────────────────────────────────────────────────────────

Write-Info "Stopping cluster '$ClusterName'... (this may take 2-5 minutes)"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    az aks stop --name $ClusterName --resource-group $ResourceGroup
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to stop cluster."
        exit 1
    }
} catch {
    Write-Err "Failed to stop cluster: $_"
    exit 1
}

$stopwatch.Stop()
$elapsed = $stopwatch.Elapsed

# ── Verify ───────────────────────────────────────────────────────────────────

$clusterInfo = az aks show --name $ClusterName --resource-group $ResourceGroup --output json 2>$null | ConvertFrom-Json
$newState = $clusterInfo.powerState.code

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          Cluster Stopped                                     ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Cluster:          $ClusterName" -ForegroundColor White
Write-Host "  Power State:      $newState" -ForegroundColor $(if ($newState -eq "Stopped") { "Green" } else { "Yellow" })
Write-Host "  Stop Duration:    $("{0:mm\:ss}" -f $elapsed)" -ForegroundColor White
Write-Host ""
Write-Host "  Estimated Savings:" -ForegroundColor White
Write-Host "    Per Day:        ~`$$(("{0:N2}" -f $dailySavings))" -ForegroundColor Green
Write-Host "    Per Month:      ~`$$(("{0:N2}" -f $monthlySavings)) (if stopped full-time)" -ForegroundColor Green
Write-Host ""
Write-Warn "While stopped:"
Write-Warn "  - kubectl commands will NOT work"
Write-Warn "  - Workloads are NOT running"
Write-Warn "  - You still pay for OS disks and storage"
Write-Host ""
Write-Info "To start the cluster:  .\scripts\start-lab.ps1 -Environment $Environment"
Write-Host ""
