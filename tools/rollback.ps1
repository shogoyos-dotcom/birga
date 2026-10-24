<#
.SYNOPSIS
    Color Land 3D — Rollback & Recovery Workflow Script
.DESCRIPTION
    Reverts the project to a specified target Git tag / release.
    Supports Android Recovery Build mode by assigning a strictly higher versionCode
    so the recovery APK installs cleanly over newer faulty APKs without requiring
    app uninstallation or wiping user save data.
.PARAMETER TargetTag
    The Git tag to restore (e.g. "v1.00.000").
.PARAMETER Reason
    The reason for rolling back.
.PARAMETER BuildRecoveryApk
    Whether to build an installable Android ARM64 recovery APK immediately.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetTag,

    [Parameter(Mandatory=$true)]
    [string]$Reason,

    [switch]$BuildRecoveryApk = $true
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$unityProject = Join-Path $repoRoot "color_land_unity"
$unityExe = "C:\Program Files\Unity 6000.6.7f1\Editor\Unity.com"
$dotnetExe = "C:\Program Files\Unity 6000.6.7f1\Editor\Data\DotNetSdk\dotnet.exe"
$registryFile = Join-Path $repoRoot "releases_registry.json"
$rollbackLogFile = Join-Path $repoRoot "rollback_log.md"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "COLOR LAND 3D — ROLLBACK & RECOVERY PIPELINE" -ForegroundColor Cyan
Write-Host "Target Tag : $TargetTag" -ForegroundColor Yellow
Write-Host "Reason     : $Reason" -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Verify tag exists
Set-Location $repoRoot
$tagExists = git tag -l $TargetTag
if (-not $tagExists) {
    Write-Error "Xatolik: '$TargetTag' nomli Git tag topilmadi!"
}

# 2. Read latest registry to get current highest versionCode
$currentVersionCode = 1000000
$rejectedVersion = "Unknown"
if (Test-Path $registryFile) {
    try {
        $reg = Get-Content $registryFile -Raw | ConvertFrom-Json
        if ($reg.latest_version_code) {
            $currentVersionCode = [int]$reg.latest_version_code
        }
        if ($reg.latest_version) {
            $rejectedVersion = $reg.latest_version
        }
    } catch { }
}

$recoveryVersionCode = $currentVersionCode + 1
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
$tagVersion = $TargetTag.TrimStart("v")

Write-Host "[1/5] Rollback jurnali qayd etilmoqda..." -ForegroundColor Green
$logEntry = @"
## [ROLLBACK] $timestamp
- **Tiklanayotgan versiya (Target)**: $tagVersion ($TargetTag)
- **Rad etilgan versiya (Rejected)**: $rejectedVersion
- **Amaldagi eng yuqori versionCode**: $currentVersionCode
- **Recovery versionCode**: $recoveryVersionCode
- **Sabab**: $Reason
- **Ijrochi**: Automated Rollback System
---
"@

if (Test-Path $rollbackLogFile) {
    $existing = Get-Content $rollbackLogFile -Raw
    Set-Content -Path $rollbackLogFile -Value ($logEntry + "`n" + $existing)
} else {
    Set-Content -Path $rollbackLogFile -Value ("# Color Land 3D — Rollback & Recovery Log`n`n" + $logEntry)
}

# 3. Checkout tag
Write-Host "[2/5] Git orqali '$TargetTag' holatiga o'tilmoqda..." -ForegroundColor Green
git checkout $TargetTag

# 4. Run automated tests
Write-Host "[3/5] Avtomatlashtirilgan testlar tekshirilmoqda..." -ForegroundColor Green
Set-Location $unityProject
if (Test-Path $dotnetExe) {
    & $dotnetExe run --project ColorLand.Unity.csproj
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Xatolik: '$TargetTag' versiyasidagi testlar muvaffaqiyatsiz bo'ldi!"
    }
}

# 5. Build Recovery APK if requested
if ($BuildRecoveryApk) {
    Write-Host "[4/5] Android Recovery ARM64 APK yig'ilmoqda (versionCode: $recoveryVersionCode)..." -ForegroundColor Green
    
    $recoveryArgs = @(
        "-batchmode",
        "-projectPath", $unityProject,
        "-executeMethod", "ColorLand.Editor.ReleaseManager.BuildCurrentRelease",
        "-quit",
        "-logFile", "-"
    )
    
    & $unityExe $recoveryArgs
    
    $recoveryApkName = "ColorLand3D_v${tagVersion}_recovery_arm64.apk"
    $releaseDir = Join-Path $repoRoot "Releases\$tagVersion"
    $builtApk = Join-Path $releaseDir "ColorLand3D_v${tagVersion}_arm64.apk"
    
    if (Test-Path $builtApk) {
        $recoveryApkPath = Join-Path $releaseDir $recoveryApkName
        Copy-Item -Path $builtApk -Destination $recoveryApkPath -Force
        Write-Host "Recovery APK saqlandi: $recoveryApkPath" -ForegroundColor Cyan
    }
}

# 6. Update registry
Write-Host "[5/5] Global reliz reyestri yangilanmoqda (Status: ROLLED_BACK)..." -ForegroundColor Green
$newReg = @{
    latest_version = $tagVersion
    latest_version_code = $recoveryVersionCode
    latest_status = "ROLLED_BACK"
    restored_tag = $TargetTag
    rollback_reason = $Reason
    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json

Set-Content -Path $registryFile -Value $newReg

Write-Host "=================================================" -ForegroundColor Green
Write-Host "ROLLBACK MUVAFFAQIYATLI YAKUNLANDI!" -ForegroundColor Green
Write-Host "Tiklandi: $TargetTag | Yangi recovery versionCode: $recoveryVersionCode" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
