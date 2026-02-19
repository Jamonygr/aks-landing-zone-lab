#Requires -Version 5.1
<#
.SYNOPSIS
    Deploy Kubernetes workloads to the AKS cluster.

.DESCRIPTION
    Applies all K8s manifests from the k8s/ directory in a logical order:
    namespaces -> security -> storage -> apps -> monitoring -> autoscaling.
    Waits for deployments to become ready and prints a status summary.

.PARAMETER ManifestRoot
    Root directory containing K8s manifests. Default: k8s/ relative to repo root.

.PARAMETER Environment
    Terraform environment used to read outputs for manifest rendering (dev, lab, prod, staging).

.PARAMETER Namespace
    Override namespace for all manifests. If omitted, uses namespace in manifests.

.PARAMETER DryRun
    Perform a dry-run without actually applying.

.PARAMETER SkipManifestRendering
    Skip Terraform-driven token rendering for app manifests.

.PARAMETER WaitTimeout
    Timeout in seconds for waiting on deployments. Default: 120.

.PARAMETER ImageTag
    Container tag used for the learning-hub image when rendering manifests.

.EXAMPLE
    .\scripts\deploy-workloads.ps1

.EXAMPLE
    .\scripts\deploy-workloads.ps1 -Environment lab -DryRun

.EXAMPLE
    .\scripts\deploy-workloads.ps1 -SkipManifestRendering -WaitTimeout 300

.EXAMPLE
    .\scripts\deploy-workloads.ps1 -Environment lab -ImageTag "v1.0.0"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("dev", "lab", "prod", "staging")]
    [string]$Environment = "lab",

    [Parameter()]
    [string]$ManifestRoot,

    [Parameter()]
    [string]$Namespace,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$SkipManifestRendering,

    [Parameter()]
    [int]$WaitTimeout = 120,

    [Parameter()]
    [string]$ImageTag = "latest"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -- Helpers -----------------------------------------------------------------

function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN]    $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR]   $Msg" -ForegroundColor Red }

function Set-TemplateTokens {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [hashtable]$Tokens
    )

    if (-not (Test-Path $Path)) {
        throw "Template file not found: $Path"
    }

    $content = Get-Content -Path $Path -Raw
    foreach ($token in $Tokens.Keys) {
        $content = $content.Replace($token, [string]$Tokens[$token])
    }

    Set-Content -Path $Path -Value $content -NoNewline
}

function Assert-NoTemplateTokens {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $content = Get-Content -Path $Path -Raw
    $matches = [regex]::Matches($content, "__[A-Z0-9_]+__")
    if ($matches.Count -gt 0) {
        $tokens = @($matches | ForEach-Object { $_.Value } | Sort-Object -Unique)
        throw "Unresolved template tokens in ${Path}: $($tokens -join ', ')"
    }
}

function Resolve-TerraformOutputValue {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Outputs,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $property = $Outputs.PSObject.Properties[$Name]
    if (-not $property) {
        return ""
    }

    $value = $property.Value.value
    if ($null -eq $value) {
        return ""
    }

    return [string]$value
}

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
Write-Host "+------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "|          AKS Landing Zone Lab - Deploy Workloads          |" -ForegroundColor Cyan
Write-Host "+------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Warn "DRY RUN mode - no changes will be applied."
    Write-Host ""
}

if ([string]::IsNullOrWhiteSpace($ImageTag)) {
    Write-Err "ImageTag cannot be empty."
    exit 1
}

$renderedManifestRoot = $null

if (-not $SkipManifestRendering) {
    Write-Info "Rendering app manifests from Terraform outputs for '$Environment'..."

    $terraformOutputs = $null
    $stateKey = "aks-landing-zone-lab-$Environment.tfstate"

    Push-Location $rootDir
    try {
        terraform init -input=false -reconfigure -backend-config="key=$stateKey" 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "terraform init failed for state key '$stateKey'"
        }

        $terraformOutputJson = terraform output -json 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($terraformOutputJson)) {
            throw "terraform output is unavailable"
        }

        $terraformOutputs = $terraformOutputJson | ConvertFrom-Json
    } catch {
        Write-Err "Failed to read Terraform outputs for manifest rendering."
        Write-Err "Run .\scripts\deploy.ps1 -Environment $Environment first, or use -SkipManifestRendering."
        Write-Err "Details: $_"
        exit 1
    } finally {
        Pop-Location
    }

    $values = @{
        acr_login_server            = Resolve-TerraformOutputValue -Outputs $terraformOutputs -Name "acr_login_server"
        workload_identity_client_id = Resolve-TerraformOutputValue -Outputs $terraformOutputs -Name "workload_identity_client_id"
        key_vault_name              = Resolve-TerraformOutputValue -Outputs $terraformOutputs -Name "key_vault_name"
        tenant_id                   = Resolve-TerraformOutputValue -Outputs $terraformOutputs -Name "tenant_id"
        sql_server_fqdn             = Resolve-TerraformOutputValue -Outputs $terraformOutputs -Name "sql_server_fqdn"
        sql_database_name           = Resolve-TerraformOutputValue -Outputs $terraformOutputs -Name "sql_database_name"
    }

    if ([string]::IsNullOrWhiteSpace($values.sql_database_name)) {
        $values.sql_database_name = "learninghub"
    }

    $requiredOutputNames = @(
        "acr_login_server",
        "workload_identity_client_id",
        "key_vault_name",
        "tenant_id",
        "sql_server_fqdn"
    )

    $missingOutputs = @()
    foreach ($name in $requiredOutputNames) {
        if ([string]::IsNullOrWhiteSpace($values[$name])) {
            $missingOutputs += $name
        }
    }

    if ($missingOutputs.Count -gt 0) {
        Write-Err "Missing Terraform outputs required for learning-hub deployment: $($missingOutputs -join ', ')"
        Write-Err "Ensure SQL database is enabled and terraform apply has completed for '$Environment'."
        exit 1
    }

    $renderedManifestRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("aks-manifests-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $renderedManifestRoot -Force | Out-Null
    Copy-Item -Path (Join-Path $ManifestRoot "*") -Destination $renderedManifestRoot -Recurse -Force

    $tokens = @{
        "__ACR_LOGIN_SERVER__"             = $values.acr_login_server
        "__LEARNING_HUB_IMAGE_TAG__"       = $ImageTag
        "__WORKLOAD_IDENTITY_CLIENT_ID__" = $values.workload_identity_client_id
        "__SQL_SERVER_FQDN__"             = $values.sql_server_fqdn
        "__SQL_DATABASE_NAME__"           = $values.sql_database_name
        "__KEY_VAULT_NAME__"              = $values.key_vault_name
        "__TENANT_ID__"                   = $values.tenant_id
        "__ENVIRONMENT__"                 = $Environment
    }

    $templatedManifests = @(
        (Join-Path $renderedManifestRoot "apps\learning-hub.yaml"),
        (Join-Path $renderedManifestRoot "apps\db-seed-job.yaml"),
        (Join-Path $renderedManifestRoot "autoscaling\hpa-learning-hub.yaml")
    )

    foreach ($manifestPath in $templatedManifests) {
        if (Test-Path $manifestPath) {
            Set-TemplateTokens -Path $manifestPath -Tokens $tokens
            Assert-NoTemplateTokens -Path $manifestPath
        }
    }

    $ManifestRoot = $renderedManifestRoot
    Write-Success "Rendered manifests: $ManifestRoot"
    Write-Host ""
} else {
    Write-Warn "Skipping manifest rendering. Ensure app manifests are already configured."
    Write-Host ""
}

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

$kedaCrdsInstalled = $false
try {
    kubectl get crd scaledobjects.keda.sh triggerauthentications.keda.sh 1>$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        $kedaCrdsInstalled = $true
    }
} catch {
    $kedaCrdsInstalled = $false
}

if ($kedaCrdsInstalled) {
    Write-Info "KEDA CRDs detected; autoscaling/keda-scaledobject.yaml will be applied."
} else {
    Write-Warn "KEDA CRDs not detected; autoscaling/keda-scaledobject.yaml will be skipped."
}
Write-Host ""

# -- Define apply order ------------------------------------------------------

$applyOrder = @(
    @{ Name = "Namespaces";  Path = "namespaces"  }
    @{ Name = "Security";    Path = "security"    }
    @{ Name = "Storage";     Path = "storage"     }
    @{ Name = "Apps";        Path = "apps"        }
    @{ Name = "Monitoring";  Path = "monitoring"  }
    @{ Name = "Autoscaling"; Path = "autoscaling" }
)

$results = @()

foreach ($stage in $applyOrder) {
    $stageDir = Join-Path $ManifestRoot $stage.Path

    if (-not (Test-Path $stageDir)) {
        Write-Warn "Skipping '$($stage.Name)' - directory not found: $stageDir"
        $results += @{ Stage = $stage.Name; Status = "Skipped"; Files = 0 }
        continue
    }

    $yamlFiles = @(Get-ChildItem -Path $stageDir -Filter "*.yaml" -File | Sort-Object Name)

    if ($stage.Path -eq "namespaces") {
        $yamlFiles = @($yamlFiles | Sort-Object `
            @{ Expression = { if ($_.Name -eq "namespaces.yaml") { 0 } else { 100 } } }, `
            @{ Expression = { $_.Name } })
    }

    if ($stage.Path -eq "apps") {
        $yamlFiles = @($yamlFiles | Sort-Object `
            @{ Expression = { if ($_.Name -eq "learning-hub.yaml") { 0 } elseif ($_.Name -eq "db-seed-job.yaml") { 999 } else { 100 } } }, `
            @{ Expression = { $_.Name } })
    }

    if ($stage.Path -eq "autoscaling" -and -not $kedaCrdsInstalled) {
        $kedaManifest = @($yamlFiles | Where-Object { $_.Name -eq "keda-scaledobject.yaml" })
        if ($kedaManifest.Count -gt 0) {
            Write-Warn "Skipping keda-scaledobject.yaml because KEDA CRDs are not installed in this cluster."
            $yamlFiles = @($yamlFiles | Where-Object { $_.Name -ne "keda-scaledobject.yaml" })
        }
    }

    if ($yamlFiles.Count -eq 0) {
        Write-Warn "Skipping '$($stage.Name)' - no YAML files found."
        $results += @{ Stage = $stage.Name; Status = "Skipped"; Files = 0 }
        continue
    }

    Write-Info "Applying $($stage.Name) - $($yamlFiles.Count) files..."

    $stageSuccess = $true
    foreach ($file in $yamlFiles) {
        $applyArgs = @("apply", "-f", $file.FullName)

        if ($Namespace) {
            $applyArgs += @("--namespace", $Namespace)
        }

        if ($DryRun) {
            $applyArgs += "--dry-run=client"
        }

        try {
            $output = kubectl @applyArgs 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Err "  Failed: $($file.Name)"
                Write-Err "  $output"
                $stageSuccess = $false
            } else {
                $output -split "`n" | Where-Object { $_ } | ForEach-Object {
                    Write-Host "    $_" -ForegroundColor Gray
                }
            }
        } catch {
            Write-Err "  Exception applying $($file.Name): $_"
            $stageSuccess = $false
        }
    }

    if ($stageSuccess) {
        Write-Success "  $($stage.Name) applied successfully."
        $results += @{ Stage = $stage.Name; Status = "Applied"; Files = $yamlFiles.Count }
    } else {
        Write-Warn "  $($stage.Name) had errors."
        $results += @{ Stage = $stage.Name; Status = "Errors"; Files = $yamlFiles.Count }
    }
    Write-Host ""
}

# -- Wait for deployments ----------------------------------------------------

if (-not $DryRun) {
    Write-Info "Waiting for deployments to be ready (timeout: ${WaitTimeout}s)..."
    Write-Host ""

    try {
        $deployments = kubectl get deployments --all-namespaces --output json 2>$null | ConvertFrom-Json
        if ($deployments -and $deployments.items.Count -gt 0) {
            $allReady = $true
            foreach ($dep in $deployments.items) {
                $depName = $dep.metadata.name
                $depNs   = $dep.metadata.namespace

                # Skip kube-system deployments
                if ($depNs -eq "kube-system") { continue }

                Write-Info "  Waiting for $depNs/$depName..."
                kubectl rollout status deployment/$depName -n $depNs --timeout="${WaitTimeout}s" 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Warn "  $depNs/$depName not ready within timeout."
                    $allReady = $false
                } else {
                    Write-Success "  $depNs/$depName is ready."
                }
            }

            if ($allReady) {
                Write-Success "All deployments are ready."
            } else {
                Write-Warn "Some deployments did not become ready within the timeout."
            }
        } else {
            Write-Info "No deployments found to wait for."
        }
    } catch {
        Write-Warn "Could not check deployment status: $_"
    }
}

# -- Status summary ----------------------------------------------------------

Write-Host ""
Write-Host "+------------------------------------------------------------+" -ForegroundColor Green
Write-Host "|                Workload Deployment Summary                 |" -ForegroundColor Green
Write-Host "+------------------------------------------------------------+" -ForegroundColor Green
Write-Host ""

foreach ($result in $results) {
    $statusColor = switch ($result.Status) {
        "Applied"  { "Green" }
        "Skipped"  { "Yellow" }
        "Errors"   { "Red" }
        default    { "White" }
    }
    Write-Host "  $($result.Stage.PadRight(14))" -NoNewline -ForegroundColor White
    Write-Host "$($result.Status.PadRight(10))" -NoNewline -ForegroundColor $statusColor
    Write-Host ("(" + $result.Files + " files)") -ForegroundColor Gray
}

Write-Host ""

if (-not $DryRun) {
    Write-Info "Quick checks:"
    Write-Host "  kubectl get pods --all-namespaces" -ForegroundColor Gray
    Write-Host "  kubectl get svc --all-namespaces" -ForegroundColor Gray
    Write-Host "  kubectl get ingress --all-namespaces" -ForegroundColor Gray
}

if ($renderedManifestRoot -and (Test-Path $renderedManifestRoot)) {
    Remove-Item -Path $renderedManifestRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
