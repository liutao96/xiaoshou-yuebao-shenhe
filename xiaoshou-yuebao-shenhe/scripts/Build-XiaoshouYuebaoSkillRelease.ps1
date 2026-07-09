#requires -version 5.1
<#
.SYNOPSIS
Builds the release zip and latest-version.json for xiaoshou-yuebao-shenhe.
#>

[CmdletBinding()]
param(
    [string]$SkillDir = "",
    [string]$ReleaseDir = "",
    [string]$ZipUrl = "",
    [string]$ManifestUrl = "",
    [string]$GithubRepo = "",
    [string]$GithubBranch = "main"
)

$ErrorActionPreference = "Stop"
$skillName = "xiaoshou-yuebao-shenhe"

if (-not $SkillDir) {
    $scriptDir = Split-Path -Parent $PSCommandPath
    $SkillDir = (Resolve-Path (Join-Path $scriptDir "..")).Path
}

if (-not $ReleaseDir) {
    if ($env:XIAOSHOU_YUEBAO_RELEASE_DIR) {
        $ReleaseDir = $env:XIAOSHOU_YUEBAO_RELEASE_DIR
    } else {
        $ReleaseDir = Join-Path (Get-Location).Path "outputs\skill_release"
    }
}

$versionPath = Join-Path $SkillDir "VERSION.json"
if (-not (Test-Path -LiteralPath $versionPath)) {
    throw "VERSION.json not found: $versionPath"
}

$versionInfo = Get-Content -LiteralPath $versionPath -Raw -Encoding UTF8 | ConvertFrom-Json
$version = [string]$versionInfo.version
if (-not $version) { throw "VERSION.json missing version." }

New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null
$zipPath = Join-Path $ReleaseDir "$skillName.zip"
$backupPath = Join-Path $ReleaseDir ("$skillName.backup-{0}.zip" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

if (Test-Path -LiteralPath $zipPath) {
    Copy-Item -LiteralPath $zipPath -Destination $backupPath -Force
}

Compress-Archive -LiteralPath $SkillDir -DestinationPath $zipPath -Force
$sha256 = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()

$manifest = [ordered]@{
    name = $skillName
    version = $version
    released_at = [string]$versionInfo.released_at
    release_package = "$skillName.zip"
    package_path = "$skillName.zip"
    zip_url = $ZipUrl
    manifest_url = $ManifestUrl
    github_repo = $GithubRepo
    github_branch = $GithubBranch
    sha256 = $sha256
    updater = "scripts/Update-XiaoshouYuebaoSkill.ps1"
    release_notes = @($versionInfo.release_notes)
}

$manifestPath = Join-Path $ReleaseDir "latest-version.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

$updaterSource = Join-Path $SkillDir "scripts\Update-XiaoshouYuebaoSkill.ps1"
if (Test-Path -LiteralPath $updaterSource) {
    Copy-Item -LiteralPath $updaterSource -Destination (Join-Path $ReleaseDir "Update-XiaoshouYuebaoSkill.ps1") -Force
}

Write-Host "Built release:"
Write-Host "  Version: $version"
Write-Host "  Zip: $zipPath"
Write-Host "  SHA256: $sha256"
Write-Host "  Manifest: $manifestPath"
if ($backupPath -and (Test-Path -LiteralPath $backupPath)) {
    Write-Host "  Backup: $backupPath"
}

if (-not $ZipUrl -or -not $ManifestUrl) {
    Write-Host ""
    Write-Host "GitHub release fields are not set yet. After creating a repo/release, rebuild with:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`" -ZipUrl `"https://github.com/<owner>/<repo>/releases/download/v$version/$skillName.zip`" -ManifestUrl `"https://api.github.com/repos/<owner>/<repo>/contents/release/latest-version.json?ref=main`" -GithubRepo `"<owner>/<repo>`""
}
