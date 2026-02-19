#Requires -Version 5.1
<#
.SYNOPSIS
    Remove all Kubernetes workloads from the AKS cluster.

.DESCRIPTION
    Deletes all K8s manifests from the k8s/ directory in reverse order:
    autoscaling -> monitoring -> apps -> storage -> security -> namespaces.
    Prints a cleanup summary.

.PARAMETER ManifestRoot
    Root directory containing K8s manifests. Default: k8s/ relative to repo root.

.PARAMETER SkipNamespaces
    Skip deleting namespace manifests (to preserve namespace structure).

.PARAMETER AutoApprove
    Skip confirmation prompt.

.EXAMPLE
    .\scripts\cleanup-workloads.ps1

.EXAMPLE
    .\scripts\cleanup-workloads.ps1 -SkipNamespaces

.EXAMPLE
    .\scripts\cleanup-workloads.ps1 -AutoApprove
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ManifestRoot,

    [Parameter()]
    [switch]$SkipNamespaces,

    [Parameter()]
    [switch]$AutoApprove
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -- Helpers -----------------------------------------------------------------

function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN]    $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR]   $Msg" -ForegroundColor Red }

# -- Resolve paths -----------------------------------------------------------

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir   = Split-Path -Parent $scriptDir

if (-not $ManifestRoot) {
    $ManifestRoot = Join-Path $rootDir "k8s"
}

if (-not (Test-Path $ManifestRoot)) {
    Write-Err "Manifest directory not found: $ManifestRoot"
    exit 1
}

Write-Host ""
Write-Host "+------------------------------------------------------------+" -ForegroundColor Yellow
Write-Host "|          AKS Landing Zone Lab - Cleanup Workloads         |" -ForegroundColor Yellow
Write-Host "+------------------------------------------------------------+" -ForegroundColor Yellow
Write-Host ""

# -- Verify kubectl works ----------------------------------------------------

Write-Info "Verifying kubectl connection..."
try {
    kubectl cluster-info 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "kubectl not connected" }
    Write-Success "Connected to cluster: $(kubectl config current-context 2>$null)"
} catch {
    Write-Err "Cannot connect to Kubernetes cluster."
    Write-Err "Run .\scripts\get-credentials.ps1 first."
    exit 1
}
Write-Host ""

# -- Confirm -----------------------------------------------------------------

if (-not $AutoApprove) {
    Write-Warn "This will delete all lab workloads from the cluster."
    $confirm = Read-Host "  Type 'yes' to continue"
    if ($confirm -ne "yes") {
        Write-Warn "Cleanup cancelled by user."
        exit 0
    }
    Write-Host ""
}

# -- Define delete order (reverse of apply) ----------------------------------

$deleteOrder = @(
    @{ Name = "Autoscaling"; Path = "autoscaling" }
    @{ Name = "Monitoring";  Path = "monitoring"  }
    @{ Name = "Apps";        Path = "apps"        }
    @{ Name = "Storage";     Path = "storage"     }
    @{ Name = "Security";    Path = "security"    }
)

if (-not $SkipNamespaces) {
    $deleteOrder += @{ Name = "Namespaces"; Path = "namespaces" }
} else {
    Write-Info "Skipping namespace deletion (SkipNamespaces flag set)."
}

$results = @()

foreach ($stage in $deleteOrder) {
    $stageDir = Join-Path $ManifestRoot $stage.Path

    if (-not (Test-Path $stageDir)) {
        Write-Warn "Skipping '$($stage.Name)' - directory not found."
        $results += @{ Stage = $stage.Name; Status = "Skipped"; Files = 0 }
        continue
    }

    $yamlFiles = Get-ChildItem -Path $stageDir -Filter "*.yaml" -File | Sort-Object Name -Descending
    if ($yamlFiles.Count -eq 0) {
        Write-Warn "Skipping '$($stage.Name)' - no YAML files found."
        $results += @{ Stage = $stage.Name; Status = "Skipped"; Files = 0 }
        continue
    }

    Write-Info "Deleting $($stage.Name) - $($yamlFiles.Count) files..."

    $stageSuccess = $true
    foreach ($file in $yamlFiles) {
        try {
            $output = kubectl delete -f $file.FullName --ignore-not-found=true 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warn "  Warning deleting $($file.Name): $output"
                # Don't fail on delete errors - resource may already be gone
            } else {
                $output -split "`n" | Where-Object { $_ } | ForEach-Object {
                    Write-Host "    $_" -ForegroundColor Gray
                }
            }
        } catch {
            Write-Warn "  Exception deleting $($file.Name): $_"
            $stageSuccess = $false
        }
    }

    if ($stageSuccess) {
        Write-Success "  $($stage.Name) cleaned up."
        $results += @{ Stage = $stage.Name; Status = "Deleted"; Files = $yamlFiles.Count }
    } else {
        Write-Warn "  $($stage.Name) had warnings."
        $results += @{ Stage = $stage.Name; Status = "Warnings"; Files = $yamlFiles.Count }
    }
    Write-Host ""
}

# -- Summary -----------------------------------------------------------------

Write-Host "+------------------------------------------------------------+" -ForegroundColor Green
Write-Host "|                 Workload Cleanup Summary                   |" -ForegroundColor Green
Write-Host "+------------------------------------------------------------+" -ForegroundColor Green
Write-Host ""

foreach ($result in $results) {
    $statusColor = switch ($result.Status) {
        "Deleted"  { "Green" }
        "Skipped"  { "Yellow" }
        "Warnings" { "Yellow" }
        default    { "White" }
    }
    Write-Host "  $($result.Stage.PadRight(14))" -NoNewline -ForegroundColor White
    Write-Host "$($result.Status.PadRight(10))" -NoNewline -ForegroundColor $statusColor
    Write-Host ("(" + $result.Files + " files)") -ForegroundColor Gray
}

Write-Host ""
Write-Info "Cluster workloads have been removed."
Write-Info "Infrastructure (AKS, VNets, etc.) is still running."
Write-Info "To destroy infrastructure:  .\scripts\destroy.ps1"
Write-Host ""
