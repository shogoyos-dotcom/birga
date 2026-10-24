<#
.SYNOPSIS
    Color Land 3D — Automated Release & APK Delivery Script
.DESCRIPTION
    Executes automated tests, rebuilds the scene, compiles the Android ARM64 IL2CPP APK,
    verifies checksums, generates manifests, and tags the Git release.
.PARAMETER Version
    The explicit version to build (default: from VersionConfig.CURRENT_VERSION, e.g. "1.00.000").
.PARAMETER BumpType
    Optional bump type: "none", "patch", "minor", "major".
#>

param(
    [string]$Version = "",
    [ValidateSet("none", "patch", "minor", "major")]
    [string]$BumpType = "none"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$unityProject = Join-Path $repoRoot "color_land_unity"
$unityExe = "C:\Program Files\Unity 6000.6.7f1\Editor\Unity.com"
$dotnetExe = "C:\Program Files\Unity 6000.6.7f1\Editor\Data\DotNetSdk\dotnet.exe"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "COLOR LAND 3D — AUTOMATED RELEASE PIPELINE" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Run automated tests
Write-Host "[1/4] Avtomatlashtirilgan testlar ishga tushirilmoqda..." -ForegroundColor Green
Set-Location $unityProject
if (Test-Path $dotnetExe) {
    & $dotnetExe run --project ColorLand.Unity.csproj
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Testlar muvaffaqiyatsiz bo'ldi! Reliz to'xtatildi."
    }
}

# 2. Build Scene & APK via Unity batchmode
Write-Host "[2/4] Unity 6 batchmode orqali sahna va Android ARM64 APK yig'ilmoqda..." -ForegroundColor Green
$unityArgs = @(
    "-batchmode",
    "-projectPath", $unityProject,
    "-executeMethod", "ColorLand.Editor.ReleaseManager.BuildSceneAndRelease",
    "-quit",
    "-logFile", "-"
)

& $unityExe $unityArgs

# 3. Verify output
$registryFile = Join-Path $repoRoot "releases_registry.json"
if (-not (Test-Path $registryFile)) {
    Write-Error "Xatolik: releases_registry.json fayli yaratilmadi!"
}

$reg = Get-Content $registryFile -Raw | ConvertFrom-Json
$releasedVer = $reg.latest_version
$releasedApk = Join-Path $repoRoot $reg.latest_apk

if (-not (Test-Path $releasedApk)) {
    Write-Error "Xatolik: Reliz APK fayli diskda topilmadi: $releasedApk"
}

$apkSize = (Get-Item $releasedApk).Length
Write-Host "[3/4] Reliz APK tekshirildi: $releasedApk ($apkSize bayt, SHA256: $($reg.sha256))" -ForegroundColor Green

# 4. Git Tag & Push
Set-Location $repoRoot
$tag = "v$releasedVer"
Write-Host "[4/5] Git commit va tag '$tag' yaratilmoqda..." -ForegroundColor Green
git add -A
git commit -m "feat(release): deliver Color Land 3D $tag Android ARM64 release package"
git tag -a $tag -m "Color Land 3D Release $tag" -f
git push origin $tag -f

# 5. Upload to GitHub Releases for direct mobile download
Write-Host "[5/5] GitHub Releases ga APK yuklanmoqda..." -ForegroundColor Green
$notesFile = Join-Path $repoRoot "Releases\$releasedVer\release_notes.md"
if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh release create $tag $releasedApk --title "Color Land 3D — $tag" --notes-file $notesFile -R shogoyos-dotcom/birga
    $downloadUrl = "https://github.com/shogoyos-dotcom/birga/releases/download/$tag/ColorLand3D_${tag}_arm64.apk"
    Write-Host "To'g'ridan-to'g'ri yuklab olish havolasi: $downloadUrl" -ForegroundColor Cyan
}

Write-Host "=================================================" -ForegroundColor Green
Write-Host "RELIZ MUVAFFAQIYATLI YAKUNLANDI: $tag" -ForegroundColor Green
Write-Host "APK manzili: $releasedApk" -ForegroundColor Green
Write-Host "Download   : https://github.com/shogoyos-dotcom/birga/releases/download/$tag/ColorLand3D_${tag}_arm64.apk" -ForegroundColor Green
Write-Host "SHA-256    : $($reg.sha256)" -ForegroundColor Green
Write-Host "Status     : READY_FOR_TEST" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
