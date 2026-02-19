#Requires -Version 5.1
<#
.SYNOPSIS
    Build and push the Learning Hub container image to ACR.

.DESCRIPTION
    Builds the Next.js Learning Hub Docker image and pushes it to the
    Azure Container Registry using 'az acr build' (cloud build).

.PARAMETER AcrName
    Name of the Azure Container Registry. Auto-detected from terraform output if omitted.

.PARAMETER Tag
    Image tag. Default: latest.

.PARAMETER Environment
    Terraform environment used when auto-detecting ACR output (dev, lab, prod, staging).

.PARAMETER LocalBuild
    Use local Docker daemon instead of ACR cloud build.

.EXAMPLE
    .\scripts\build-app.ps1

.EXAMPLE
    .\scripts\build-app.ps1 -AcrName "acrakslablab" -Tag "v1.0.0"

.EXAMPLE
    .\scripts\build-app.ps1 -LocalBuild

.EXAMPLE
    .\scripts\build-app.ps1 -Environment prod -Tag "v1.0.0"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$AcrName,

    [Parameter()]
    [string]$Tag = "latest",

    [Parameter()]
    [ValidateSet("dev", "lab", "prod", "staging")]
    [string]$Environment = "lab",

    [Parameter()]
    [switch]$LocalBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR]   $Msg" -ForegroundColor Red }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir   = Split-Path -Parent $scriptDir
$appDir    = Join-Path $rootDir "app"

Write-Host ""
Write-Host "+------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "|      AKS Learning Hub - Build & Push Container Image      |" -ForegroundColor Cyan
Write-Host "+------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# -- Resolve ACR name -------------------------------------------------------

if (-not $AcrName) {
    Write-Info "Detecting ACR name from Terraform output..."
    try {
        $stateKey = "aks-landing-zone-lab-$Environment.tfstate"
        Push-Location $rootDir
        terraform init -input=false -reconfigure -backend-config="key=$stateKey" 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "terraform init failed for state key '$stateKey'"
        }
        $AcrName = (terraform output -raw acr_login_server 2>$null) -replace '\.azurecr\.io$', ''
        Pop-Location
        if (-not $AcrName) { throw "empty" }
        Write-Info "ACR detected: $AcrName"
    } catch {
        Write-Err "Could not auto-detect ACR name. Pass -AcrName parameter."
        exit 1
    }
}

$imageName = "learning-hub"
$fullTag   = "${AcrName}.azurecr.io/${imageName}:${Tag}"

Write-Info "Image: $fullTag"
Write-Info "App directory: $appDir"

if (-not (Test-Path $appDir)) {
    Write-Err "App directory not found: $appDir"
    exit 1
}

# -- Build -------------------------------------------------------------------

if ($LocalBuild) {
    Write-Info "Building locally with Docker..."

    # Check Docker
    try {
        docker version 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Docker not running" }
    } catch {
        Write-Err "Docker is not available. Install Docker Desktop or use cloud build (default)."
        exit 1
    }

    # Login to ACR
    Write-Info "Logging in to ACR..."
    az acr login --name $AcrName
    if ($LASTEXITCODE -ne 0) { Write-Err "ACR login failed."; exit 1 }

    # Build
    Write-Info "Building Docker image..."
    docker build -t $fullTag $appDir
    if ($LASTEXITCODE -ne 0) { Write-Err "Docker build failed."; exit 1 }

    # Push
    Write-Info "Pushing to ACR..."
    docker push $fullTag
    if ($LASTEXITCODE -ne 0) { Write-Err "Docker push failed."; exit 1 }

} else {
    Write-Info "Building with ACR cloud build (no local Docker required)..."
    az acr build --registry $AcrName --image "${imageName}:${Tag}" $appDir
    if ($LASTEXITCODE -ne 0) {
        Write-Err "ACR cloud build failed."
        exit 1
    }
}

Write-Host ""
Write-Success "Image built and pushed: $fullTag"
Write-Host ""
Write-Info "Next steps:"
Write-Host "  1. .\scripts\deploy-workloads.ps1 -Environment $Environment -ImageTag $Tag" -ForegroundColor Gray
Write-Host "  2. kubectl rollout status deployment/learning-hub -n lab-apps" -ForegroundColor Gray
Write-Host "  3. kubectl get ingress -n lab-apps" -ForegroundColor Gray
Write-Host ""
