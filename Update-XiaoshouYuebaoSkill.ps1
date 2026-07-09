#requires -version 5.1
<#
.SYNOPSIS
Updates the xiaoshou-yuebao-shenhe Codex skill from a version manifest.

.DESCRIPTION
The updater checks a local or remote latest-version.json, compares versions,
downloads the release zip, verifies SHA256 when provided, backs up the current
skill folder, installs the new version, and writes a log.
#>

[CmdletBinding()]
param(
    [string]$ManifestUrl = "",
    [string]$ManifestFile = "",
    [string]$GithubRepo = "",
    [string]$GithubBranch = "main",
    [string]$GithubToken = $env:GITHUB_TOKEN,
    [string]$InstallRoot = (Join-Path $HOME ".codex\skills"),
    [string]$SkillName = "xiaoshou-yuebao-shenhe",
    [string]$LogDir = (Join-Path $HOME ".codex\logs"),
    [switch]$CheckOnly,
    [switch]$Yes,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-UpdateLog {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Write-Host $line
    if ($script:LogPath) {
        Add-Content -LiteralPath $script:LogPath -Value $line -Encoding UTF8
    }
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "JSON file not found: $Path"
    }
    $json = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $json = $json.TrimStart([char]0xFEFF)
    return $json | ConvertFrom-Json
}

function ConvertTo-VersionValue {
    param([string]$Version)
    if ([string]::IsNullOrWhiteSpace($Version)) {
        return [version]"0.0.0"
    }
    $clean = ($Version -replace '[^\d\.].*$', '')
    try { return [version]$clean } catch { return [version]"0.0.0" }
}

function Get-ManifestFromUrl {
    param([string]$Url)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $headers = @{
        "User-Agent" = "xiaoshou-yuebao-shenhe-updater"
        "Cache-Control" = "no-cache"
    }
    if ($GithubToken) {
        $headers["Authorization"] = "Bearer $GithubToken"
    }
    $response = Invoke-RestMethod -Uri $Url -Headers $headers -TimeoutSec 30
    if ($response.content -and $response.encoding -eq "base64") {
        $base64 = ([string]$response.content) -replace '\s', ''
        $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($base64))
        $json = $json.TrimStart([char]0xFEFF)
        return $json | ConvertFrom-Json
    }
    return $response
}

function Resolve-Manifest {
    $scriptDir = Split-Path -Parent $PSCommandPath
    $skillDir = Split-Path -Parent $scriptDir
    $localVersionPath = Join-Path $skillDir "VERSION.json"
    $localVersion = $null
    if (Test-Path -LiteralPath $localVersionPath) {
        $localVersion = Read-JsonFile -Path $localVersionPath
    }

    if ($ManifestFile) {
        $resolved = Resolve-Path -LiteralPath $ManifestFile
        $script:ManifestBaseDir = Split-Path -Parent $resolved.Path
        return Read-JsonFile -Path $resolved.Path
    }

    if (-not $ManifestUrl -and $GithubRepo) {
        $ManifestUrl = "https://api.github.com/repos/$GithubRepo/contents/release/latest-version.json?ref=$GithubBranch"
    }

    if (-not $ManifestUrl -and $localVersion -and $localVersion.update -and $localVersion.update.manifest_url) {
        $ManifestUrl = [string]$localVersion.update.manifest_url
    }

    if (-not $ManifestUrl -and $localVersion -and $localVersion.update -and $localVersion.update.github_repo) {
        $repo = [string]$localVersion.update.github_repo
        $branch = [string]$localVersion.update.github_branch
        if (-not $branch) { $branch = "main" }
        $ManifestUrl = "https://api.github.com/repos/$repo/contents/release/latest-version.json?ref=$branch"
    }

    if (-not $ManifestUrl) {
        $candidate = Join-Path (Split-Path -Parent $skillDir) "latest-version.json"
        if (Test-Path -LiteralPath $candidate) {
            $script:ManifestBaseDir = Split-Path -Parent $candidate
            return Read-JsonFile -Path $candidate
        }
        $candidate = Join-Path $scriptDir "latest-version.json"
        if (Test-Path -LiteralPath $candidate) {
            $script:ManifestBaseDir = Split-Path -Parent $candidate
            return Read-JsonFile -Path $candidate
        }
        throw "No update manifest found. Pass -ManifestUrl, -GithubRepo, or -ManifestFile."
    }

    $script:ManifestBaseDir = ""
    return Get-ManifestFromUrl -Url $ManifestUrl
}

function Resolve-PackageSource {
    param($Manifest)
    if ($Manifest.zip_url -and ([string]$Manifest.zip_url) -notmatch '^TODO') {
        return @{ Type = "url"; Value = [string]$Manifest.zip_url }
    }
    if ($Manifest.package_url -and ([string]$Manifest.package_url) -notmatch '^TODO') {
        return @{ Type = "url"; Value = [string]$Manifest.package_url }
    }
    if ($Manifest.package_path) {
        $path = [string]$Manifest.package_path
        if (-not [IO.Path]::IsPathRooted($path)) {
            if (-not $script:ManifestBaseDir) {
                throw "Manifest uses package_path but no local manifest base directory is available."
            }
            $path = Join-Path $script:ManifestBaseDir $path
        }
        return @{ Type = "file"; Value = $path }
    }
    throw "Manifest does not contain zip_url, package_url, or package_path."
}

function Assert-SafeSkillPath {
    param([string]$InstallRootPath, [string]$InstallDirPath, [string]$ExpectedSkillName)
    $rootFull = [IO.Path]::GetFullPath($InstallRootPath)
    $dirFull = [IO.Path]::GetFullPath($InstallDirPath)
    if ((Split-Path -Leaf $dirFull) -ne $ExpectedSkillName) {
        throw "Refusing to update unexpected skill directory: $dirFull"
    }
    if (-not $dirFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to update outside install root. Root=$rootFull Target=$dirFull"
    }
}

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$script:LogPath = Join-Path $LogDir ("xiaoshou-yuebao-shenhe-update-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

$installRootFull = [IO.Path]::GetFullPath($InstallRoot)
$installDir = Join-Path $installRootFull $SkillName
Assert-SafeSkillPath -InstallRootPath $installRootFull -InstallDirPath $installDir -ExpectedSkillName $SkillName

Write-UpdateLog "Checking $SkillName update."
Write-UpdateLog "Install dir: $installDir"

$localVersionPath = Join-Path $installDir "VERSION.json"
$localVersion = "0.0.0"
if (Test-Path -LiteralPath $localVersionPath) {
    $local = Read-JsonFile -Path $localVersionPath
    if ($local.version) { $localVersion = [string]$local.version }
}
Write-UpdateLog "Current version: $localVersion"

$manifest = Resolve-Manifest
$remoteVersion = [string]$manifest.version
if (-not $remoteVersion) { throw "Manifest missing version." }
Write-UpdateLog "Latest version: $remoteVersion"

$isNewer = (ConvertTo-VersionValue $remoteVersion) -gt (ConvertTo-VersionValue $localVersion)
if (-not $isNewer -and -not $Force) {
    Write-UpdateLog "Already up to date."
    exit 0
}

if ($CheckOnly) {
    if ($isNewer) {
        Write-UpdateLog "Update available: $localVersion -> $remoteVersion"
        if ($manifest.release_notes) {
            Write-UpdateLog "Release notes:"
            foreach ($note in $manifest.release_notes) { Write-UpdateLog " - $note" }
        }
    }
    exit 0
}

if (-not $Yes) {
    $answer = Read-Host "Update $SkillName from $localVersion to $remoteVersion? Type Y to continue"
    if ($answer -ne "Y" -and $answer -ne "y") {
        Write-UpdateLog "User cancelled."
        exit 1
    }
}

$package = Resolve-PackageSource -Manifest $manifest
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("xiaoshou-yuebao-update-{0}" -f ([Guid]::NewGuid().ToString("N")))
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
$zipPath = Join-Path $tempRoot "package.zip"

if ($package.Type -eq "url") {
    Write-UpdateLog "Downloading package: $($package.Value)"
    $downloadHeaders = @{ "User-Agent" = "xiaoshou-yuebao-shenhe-updater" }
    if ($GithubToken) {
        $downloadHeaders["Authorization"] = "Bearer $GithubToken"
    }
    Invoke-WebRequest -Uri $package.Value -OutFile $zipPath -Headers $downloadHeaders -TimeoutSec 120
} else {
    Write-UpdateLog "Using local package: $($package.Value)"
    if (-not (Test-Path -LiteralPath $package.Value)) { throw "Package not found: $($package.Value)" }
    Copy-Item -LiteralPath $package.Value -Destination $zipPath -Force
}

if ($manifest.sha256) {
    $actualHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $expectedHash = ([string]$manifest.sha256).ToLowerInvariant()
    Write-UpdateLog "Downloaded SHA256: $actualHash"
    if ($actualHash -ne $expectedHash) {
        throw "SHA256 mismatch. Expected=$expectedHash Actual=$actualHash"
    }
}

$extractDir = Join-Path $tempRoot "extract"
New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

$newRoot = Join-Path $extractDir $SkillName
if (-not (Test-Path -LiteralPath (Join-Path $newRoot "SKILL.md"))) {
    $candidate = Get-ChildItem -LiteralPath $extractDir -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") } | Select-Object -First 1
    if ($candidate) { $newRoot = $candidate.FullName }
}
if (-not (Test-Path -LiteralPath (Join-Path $newRoot "SKILL.md"))) {
    throw "Package does not contain a valid skill root with SKILL.md."
}
if (-not (Test-Path -LiteralPath (Join-Path $newRoot "VERSION.json"))) {
    throw "Package does not contain VERSION.json."
}

$newVersionObj = Read-JsonFile -Path (Join-Path $newRoot "VERSION.json")
if ([string]$newVersionObj.version -ne $remoteVersion) {
    throw "Package VERSION.json version does not match manifest. Package=$($newVersionObj.version) Manifest=$remoteVersion"
}

$backupRoot = Join-Path $HOME ".codex\skill-backups"
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
$backupDir = Join-Path $backupRoot ("{0}-{1}" -f $SkillName, (Get-Date -Format "yyyyMMdd-HHmmss"))

try {
    if (Test-Path -LiteralPath $installDir) {
        Write-UpdateLog "Backing up current skill to: $backupDir"
        Copy-Item -LiteralPath $installDir -Destination $backupDir -Recurse -Force
        Write-UpdateLog "Removing old skill directory."
        Remove-Item -LiteralPath $installDir -Recurse -Force
    } else {
        Write-UpdateLog "No existing skill directory found; installing fresh."
        New-Item -ItemType Directory -Force -Path $installRootFull | Out-Null
    }

    Write-UpdateLog "Installing new skill."
    Copy-Item -LiteralPath $newRoot -Destination $installDir -Recurse -Force
    Write-UpdateLog "Update complete: $SkillName $remoteVersion"
    Write-UpdateLog "Restart Codex / Claude Code to load the updated skill."
}
catch {
    Write-UpdateLog "Update failed: $($_.Exception.Message)"
    if ((-not (Test-Path -LiteralPath $installDir)) -and (Test-Path -LiteralPath $backupDir)) {
        Write-UpdateLog "Restoring backup."
        Copy-Item -LiteralPath $backupDir -Destination $installDir -Recurse -Force
    }
    throw
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
