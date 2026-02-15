#Requires -Version 5.1
<#
.SYNOPSIS
    Start the AKS lab cluster.

.DESCRIPTION
    Starts a previously stopped AKS cluster using 'az aks start', waits
    for it to be fully ready, and prints the cluster status.

.PARAMETER Environment
    Target environment (dev, lab, prod, staging). Default: dev.

.PARAMETER ClusterName
    AKS cluster name. If omitted, derived from environment.

.PARAMETER ResourceGroup
    Resource group containing the cluster. If omitted, derived from environment.

.PARAMETER WaitTimeout
    Timeout in seconds for waiting on cluster readiness. Default: 600 (10 min).

.EXAMPLE
    .\scripts\start-lab.ps1

.EXAMPLE
    .\scripts\start-lab.ps1 -Environment lab

.EXAMPLE
    .\scripts\start-lab.ps1 -WaitTimeout 900
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
    [int]$WaitTimeout = 600
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
Write-Host "║          AKS Landing Zone Lab - Start Cluster               ║" -ForegroundColor Cyan
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

if ($currentState -eq "Running") {
    Write-Success "Cluster is already running."
    Write-Info "No action needed."
    Write-Host ""

    # Still print node status
    try {
        az aks get-credentials --name $ClusterName --resource-group $ResourceGroup --overwrite-existing 2>$null
        $nodes = kubectl get nodes --output json 2>$null | ConvertFrom-Json
        if ($nodes -and $nodes.items.Count -gt 0) {
            Write-Host "  Nodes:" -ForegroundColor White
            foreach ($node in $nodes.items) {
                $name   = $node.metadata.name
                $status = ($node.status.conditions | Where-Object { $_.type -eq "Ready" }).status
                $color  = if ($status -eq "True") { "Green" } else { "Yellow" }
                Write-Host "    $name  Ready=$status" -ForegroundColor $color
            }
            Write-Host ""
        }
    } catch { }

    exit 0
}

Write-Info "Current power state: $currentState"
Write-Host ""

# ── Start cluster ───────────────────────────────────────────────────────────

Write-Info "Starting cluster '$ClusterName'... (this may take 3-10 minutes)"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    az aks start --name $ClusterName --resource-group $ResourceGroup
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to start cluster."
        exit 1
    }
} catch {
    Write-Err "Failed to start cluster: $_"
    exit 1
}

$stopwatch.Stop()
$elapsed = $stopwatch.Elapsed

Write-Success "az aks start completed in $("{0:mm\:ss}" -f $elapsed)."
Write-Host ""

# ── Wait for cluster to be ready ────────────────────────────────────────────

Write-Info "Waiting for cluster to be fully ready..."

$ready = $false
$waitStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

while (-not $ready -and $waitStopwatch.Elapsed.TotalSeconds -lt $WaitTimeout) {
    try {
        $clusterInfo = az aks show --name $ClusterName --resource-group $ResourceGroup --output json 2>$null | ConvertFrom-Json
        if ($clusterInfo.powerState.code -eq "Running" -and $clusterInfo.provisioningState -eq "Succeeded") {
            $ready = $true
        } else {
            Write-Host "." -NoNewline -ForegroundColor Gray
            Start-Sleep -Seconds 10
        }
    } catch {
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
}

$waitStopwatch.Stop()
Write-Host ""

if (-not $ready) {
    Write-Warn "Cluster did not reach 'Running' state within ${WaitTimeout}s."
    Write-Warn "It may still be starting. Check status with:"
    Write-Warn "  az aks show -n $ClusterName -g $ResourceGroup --query powerState"
    exit 1
}

Write-Success "Cluster is running."
Write-Host ""

# ── Refresh kubeconfig ──────────────────────────────────────────────────────

Write-Info "Refreshing kubeconfig..."
try {
    az aks get-credentials --name $ClusterName --resource-group $ResourceGroup --overwrite-existing 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Kubeconfig updated."
    }
} catch {
    Write-Warn "Could not refresh kubeconfig. Run get-credentials.ps1 manually."
}

# ── Verify nodes ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Info "Checking node readiness..."

$nodeReady = $false
$nodeRetries = 0
$maxNodeRetries = 12  # 2 minutes

while (-not $nodeReady -and $nodeRetries -lt $maxNodeRetries) {
    try {
        $nodes = kubectl get nodes --output json 2>$null | ConvertFrom-Json
        if ($nodes -and $nodes.items.Count -gt 0) {
            $allNodesReady = $true
            foreach ($node in $nodes.items) {
                $status = ($node.status.conditions | Where-Object { $_.type -eq "Ready" }).status
                if ($status -ne "True") {
                    $allNodesReady = $false
                    break
                }
            }
            if ($allNodesReady) {
                $nodeReady = $true
            } else {
                Write-Host "." -NoNewline -ForegroundColor Gray
                Start-Sleep -Seconds 10
                $nodeRetries++
            }
        } else {
            Write-Host "." -NoNewline -ForegroundColor Gray
            Start-Sleep -Seconds 10
            $nodeRetries++
        }
    } catch {
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep -Seconds 10
        $nodeRetries++
    }
}

Write-Host ""

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          Cluster Started                                     ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Cluster:          $ClusterName" -ForegroundColor White
Write-Host "  Power State:      $($clusterInfo.powerState.code)" -ForegroundColor Green
Write-Host "  Provisioning:     $($clusterInfo.provisioningState)" -ForegroundColor White
Write-Host "  K8s Version:      $($clusterInfo.kubernetesVersion)" -ForegroundColor White
Write-Host "  Start Duration:   $("{0:mm\:ss}" -f $elapsed)" -ForegroundColor White
Write-Host ""

if ($nodeReady) {
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
    Write-Host ""
    Write-Success "All nodes are ready."
} else {
    Write-Warn "Some nodes may still be initializing. Check with: kubectl get nodes"
}

Write-Host ""
Write-Info "Cluster is ready to use."
Write-Info "Next steps:"
Write-Host "  .\scripts\deploy-workloads.ps1" -ForegroundColor Gray
Write-Host "  kubectl get pods --all-namespaces" -ForegroundColor Gray
Write-Host ""
