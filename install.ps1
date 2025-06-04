# Takarik CLI Windows Installation Script
# PowerShell version of install.sh

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Write-Success {
    param([string]$Text)
    Write-ColorText $Text "Green"
}

function Write-Error {
    param([string]$Text)
    Write-ColorText $Text "Red"
}

function Write-Warning {
    param([string]$Text)
    Write-ColorText $Text "Yellow"
}

function Write-Info {
    param([string]$Text)
    Write-ColorText $Text "Cyan"
}

# Check if Crystal is installed
Write-Info "Checking Crystal installation..."
try {
    $crystalVersion = & crystal --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Crystal not found"
    }
    Write-Success "Crystal found: $($crystalVersion.Split("`n")[0])"
} catch {
    Write-Error "Crystal language is not installed or not in PATH."
    Write-Info "Please install Crystal from: https://crystal-lang.org/install/on_windows/"
    Write-Info "Note: Crystal on Windows is currently in preview."
    exit 1
}

# Check if Shards is installed
Write-Info "Checking Shards installation..."
try {
    $shardsVersion = & shards --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Shards not found"
    }
    Write-Success "Shards found: $($shardsVersion.Split("`n")[0])"
} catch {
    Write-Error "Shards is not installed or not in PATH."
    Write-Info "Shards should come with Crystal installation."
    exit 1
}

# Check if Git is installed
Write-Info "Checking Git installation..."
try {
    $gitVersion = & git --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Git not found"
    }
    Write-Success "Git found: $($gitVersion)"
} catch {
    Write-Error "Git is not installed or not in PATH."
    Write-Info "Please install Git from: https://git-scm.com/download/win"
    exit 1
}

$TakarikDir = "$env:USERPROFILE\.takarik"

# Check if Takarik directory already exists
if (Test-Path $TakarikDir) {
    if (-not $Force) {
        Write-Warning "Takarik directory already exists at: $TakarikDir"
        $response = Read-Host "Do you want to update Takarik? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Info "Installation cancelled."
            exit 0
        }
    }

    Write-Info "Updating Takarik..."
    try {
        Set-Location $TakarikDir
        & git pull
        if ($LASTEXITCODE -ne 0) {
            throw "Git pull failed"
        }

        $env:TAKARIK_ROOT = $TakarikDir
        & shards build --production
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed"
        }

        Write-Success "Takarik has been updated successfully!"
        exit 0
    } catch {
        Write-Error "Failed to update Takarik: $($_.Exception.Message)"
        exit 1
    }
}

Write-Info "Cloning Takarik repository to $TakarikDir..."

try {
    & git clone "https://github.com/takarik/takarik-cli" $TakarikDir
    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed"
    }
} catch {
    Write-Error "Failed to clone Takarik repository."
    exit 1
}

Write-Info "Building Takarik..."
try {
    Set-Location $TakarikDir
    $env:TAKARIK_ROOT = $TakarikDir
    & shards build --production
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
} catch {
    Write-Error "Failed to build Takarik: $($_.Exception.Message)"
    exit 1
}

# Add environment variables to PowerShell profile
Write-Info "Setting up environment variables..."

$PowerShellProfilePath = $PROFILE.CurrentUserCurrentHost
$ProfileDir = Split-Path $PowerShellProfilePath -Parent

# Create profile directory if it doesn't exist
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

# Create or update PowerShell profile
$ProfileContent = @"

# Takarik CLI
`$env:TAKARIK_ROOT = "$TakarikDir"
`$env:PATH += ";`$env:TAKARIK_ROOT\bin"
"@

if (Test-Path $PowerShellProfilePath) {
    $existingContent = Get-Content $PowerShellProfilePath -Raw -ErrorAction SilentlyContinue
    if ($existingContent -notmatch "TAKARIK_ROOT") {
        Add-Content -Path $PowerShellProfilePath -Value $ProfileContent
        Write-Info "Added Takarik configuration to PowerShell profile."
    } else {
        Write-Warning "Takarik configuration already exists in PowerShell profile."
    }
} else {
    Set-Content -Path $PowerShellProfilePath -Value $ProfileContent.TrimStart()
    Write-Info "Created PowerShell profile with Takarik configuration."
}

# Also try to set system environment variables for broader compatibility
Write-Info "Attempting to set user environment variables..."
try {
    [Environment]::SetEnvironmentVariable("TAKARIK_ROOT", $TakarikDir, [EnvironmentVariableTarget]::User)

    $currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
    $takarikBinPath = "$TakarikDir\bin"

    if ($currentPath -notlike "*$takarikBinPath*") {
        $newPath = if ($currentPath) { "$currentPath;$takarikBinPath" } else { $takarikBinPath }
        [Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::User)
        Write-Success "Environment variables set successfully."
    } else {
        Write-Info "Takarik is already in PATH."
    }
} catch {
    Write-Warning "Could not set environment variables automatically. You may need to set them manually."
}

Write-Success "Takarik CLI has been installed successfully!"
Write-Info ""
Write-Info "To start using Takarik, either:"
Write-Info "  1. Restart your PowerShell session, or"
Write-Info "  2. Run: . `$PROFILE, or"
Write-Info "  3. Set the environment variables for this session:"
Write-Info "     `$env:TAKARIK_ROOT = '$TakarikDir'"
Write-Info "     `$env:PATH += ';$TakarikDir\bin'"
Write-Info ""
Write-Info "You can then use 'takarik' command from anywhere."

# Test if takarik is immediately available
$env:TAKARIK_ROOT = $TakarikDir
$env:PATH += ";$TakarikDir\bin"

try {
    if (Test-Path "$TakarikDir\bin\takarik.exe") {
        Write-Success "Installation verified - takarik.exe found!"
    } elseif (Test-Path "$TakarikDir\bin\takarik") {
        Write-Success "Installation verified - takarik binary found!"
    } else {
        Write-Warning "Warning: Could not find takarik executable in bin directory."
        Write-Info "This might be normal if the build created a different executable name."
        Write-Info "Check the contents of: $TakarikDir\bin\"
    }
} catch {
    Write-Warning "Could not verify installation."
}