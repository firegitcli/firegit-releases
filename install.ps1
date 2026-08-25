# Installs the latest release of firegit (the firegit CLI) for Windows.
#
# Usage:
#   irm https://raw.githubusercontent.com/firegitcli/firegit-releases/main/install.ps1 | iex
#
# To pin a version:
#   $env:FIREGIT_VERSION = "v0.1.0"; irm https://raw.githubusercontent.com/firegitcli/firegit-releases/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = "firegitcli/firegit-releases"
$Binary = "firegit"

function Fail([string]$Message) {
    Write-Host "Error: ✗ $Message" -ForegroundColor Red
    exit 1
}

function Ok([string]$Message) {
    Write-Host "✓ $Message" -ForegroundColor Green
}

# Keep in sync with ascii-art.txt in firegit-cli.
function Write-AsciiArt {
    $art = @"

█████ ███ ████  █████  ███  ███ █████   
█░░░░░ █░░█░░░█ █░░░░░█ ░░░  █░░ ░█░░░  
████░░░█░░████░░████░░█░ ██░ █░░░ █░░░░ 
█░░░░  █░░█░░█░ █░░░░ █░░ █░ █░░  █░░   
█░░░░░███░█░░░█░█████░ ███ ░███░  █░░   
 ░░    ░░░ ░░  ░ ░░░░░  ░░░ ░░░░   ░░   
  ░     ░░░ ░   ░ ░░░░░  ░░░  ░░░   ░   
"@
    $esc = [char]27
    Write-Host "${esc}[1;38;2;255;105;0m$art${esc}[0m"
}

function Get-Arch {
    switch ($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { return "amd64" }
        "ARM64" { return "arm64" }
        default { Fail "unsupported architecture: $env:PROCESSOR_ARCHITECTURE" }
    }
}

function Main {
    Write-Host "Installing firegit..."
    Write-Host ""

    $archName = Get-Arch

    $version = $env:FIREGIT_VERSION
    if ([string]::IsNullOrEmpty($version)) {
        try {
            $latest = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
            $version = $latest.tag_name
        } catch {
            Fail "could not resolve latest version"
        }
        if ([string]::IsNullOrEmpty($version)) {
            Fail "could not resolve latest version"
        }
    }
    Ok "Resolved version: $version (windows/$archName)"

    $versionNoV = $version.TrimStart("v")
    $zipName = "${Binary}_${versionNoV}_windows_${archName}.zip"
    $url = "https://github.com/$Repo/releases/download/$version/$zipName"

    $tmpDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tmpDir | Out-Null

    try {
        $zipPath = Join-Path $tmpDir $zipName
        try {
            Invoke-WebRequest -Uri $url -OutFile $zipPath
        } catch {
            Fail "download failed. $version may not have a build for windows/$archName."
        }

        try {
            Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force
        } catch {
            Fail "could not unpack the $version archive for windows/$archName."
        }
        Ok "Downloaded firegit $version"

        $installDir = Join-Path $env:LOCALAPPDATA "Programs\firegit"
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null

        $exeSrc = Join-Path $tmpDir "$Binary.exe"
        $exeDst = Join-Path $installDir "$Binary.exe"
        Copy-Item -Path $exeSrc -Destination $exeDst -Force
        Ok "Installed to $installDir"

        Write-AsciiArt
        Write-Host "firegit"
        Write-Host ""
        Write-Host "  firegit $version installed -> $exeDst"
        Write-Host ""
        Write-Host "  run 'firegit --help' to get started"
        Write-Host ""

        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$installDir*") {
            $newPath = if ([string]::IsNullOrEmpty($userPath)) { $installDir } else { "$userPath;$installDir" }
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-Host "  Note: added $installDir to your user PATH. Restart your terminal for it to take effect."
        }
    }
    finally {
        Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Main
