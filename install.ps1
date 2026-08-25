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

function Get-Arch {
    switch ($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { return "amd64" }
        "ARM64" { return "arm64" }
        default { throw "Unsupported architecture: $env:PROCESSOR_ARCHITECTURE" }
    }
}

function Main {
    $archName = Get-Arch

    $version = $env:FIREGIT_VERSION
    if ([string]::IsNullOrEmpty($version)) {
        $latest = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
        $version = $latest.tag_name
        if ([string]::IsNullOrEmpty($version)) {
            throw "Could not resolve latest version"
        }
    }

    $versionNoV = $version.TrimStart("v")
    $zipName = "${Binary}_${versionNoV}_windows_${archName}.zip"
    $url = "https://github.com/$Repo/releases/download/$version/$zipName"

    $tmpDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tmpDir | Out-Null

    try {
        $zipPath = Join-Path $tmpDir $zipName
        Write-Host "Downloading $url..."
        Invoke-WebRequest -Uri $url -OutFile $zipPath

        Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force

        $installDir = Join-Path $env:LOCALAPPDATA "Programs\firegit"
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null

        $exeSrc = Join-Path $tmpDir "$Binary.exe"
        $exeDst = Join-Path $installDir "$Binary.exe"
        Copy-Item -Path $exeSrc -Destination $exeDst -Force

        Write-Host "Installed $Binary to $exeDst"

        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$installDir*") {
            [Environment]::SetEnvironmentVariable("Path", "$userPath;$installDir", "User")
            Write-Host "Added $installDir to your user PATH. Restart your terminal for it to take effect."
        }

        & $exeDst version
    }
    finally {
        Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Main
