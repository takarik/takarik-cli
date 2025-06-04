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

function Test-Command {
    param([string]$Command)
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Check if Crystal is installed
Write-Info "Checking Crystal installation..."
if (-not (Test-Command "crystal")) {
    Write-Error "Crystal language is not installed or not in PATH."
    Write-Info "Please install Crystal from one of these options:"
    Write-Info "  1. Official installer: https://crystal-lang.org/install/on_windows/"
    Write-Info "  2. Using Scoop: scoop bucket add crystal-preview https://github.com/neatorobito/scoop-crystal && scoop install crystal"
    Write-Info "  3. Using Chocolatey: choco install crystal"
    Write-Info ""
    Write-Warning "Note: Crystal on Windows is currently in preview mode."

    $installChoice = Read-Host "Would you like to try automatic installation using Scoop? (y/N)"
    if ($installChoice -eq 'y' -or $installChoice -eq 'Y') {
        Write-Info "Attempting to install Crystal via Scoop..."

        # Install Scoop if not present
        if (-not (Test-Command "scoop")) {
            Write-Info "Installing Scoop package manager..."
            try {
                Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                Invoke-RestMethod get.scoop.sh | Invoke-Expression
            } catch {
                Write-Error "Failed to install Scoop: $($_.Exception.Message)"
                exit 1
            }
        }

        # Install Crystal via Scoop
        try {
            Write-Info "Adding Crystal bucket and installing..."
            & scoop bucket add crystal-preview https://github.com/neatorobito/scoop-crystal
            & scoop install crystal

            # Refresh PATH
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

            if (Test-Command "crystal") {
                Write-Success "Crystal installed successfully!"
            } else {
                Write-Error "Crystal installation completed but crystal command not found. Please restart PowerShell and try again."
                exit 1
            }
        } catch {
            Write-Error "Failed to install Crystal via Scoop: $($_.Exception.Message)"
            Write-Info "Please install Crystal manually and run this script again."
            exit 1
        }
    } else {
        exit 1
    }
}

try {
    $crystalVersion = & crystal --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Crystal version check failed"
    }
    Write-Success "Crystal found: $($crystalVersion.Split("`n")[0])"
} catch {
    Write-Error "Crystal command failed. Please verify your Crystal installation."
    exit 1
}

# Check if Shards is installed
Write-Info "Checking Shards installation..."
if (-not (Test-Command "shards")) {
    Write-Error "Shards is not installed or not in PATH."
    Write-Info "Shards should come with Crystal installation."
    Write-Info "Try refreshing your environment or reinstalling Crystal."

    # Try to refresh PATH
    Write-Info "Attempting to refresh environment variables..."
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

    if (-not (Test-Command "shards")) {
        Write-Error "Shards still not found after PATH refresh. Please check your Crystal installation."
        exit 1
    }
}

try {
    $shardsVersion = & shards --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Shards version check failed"
    }
    Write-Success "Shards found: $($shardsVersion.Split("`n")[0])"
} catch {
    Write-Error "Shards command failed. Please verify your Crystal installation includes Shards."
    exit 1
}

# Check if Git is installed
Write-Info "Checking Git installation..."
if (-not (Test-Command "git")) {
    Write-Error "Git is not installed or not in PATH."
    Write-Info "Please install Git from: https://git-scm.com/download/win"
    Write-Info "Or use: winget install Git.Git"
    exit 1
}

try {
    $gitVersion = & git --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Git version check failed"
    }
    Write-Success "Git found: $($gitVersion)"
} catch {
    Write-Error "Git command failed. Please verify your Git installation."
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
        $originalLocation = Get-Location
        Set-Location $TakarikDir

        Write-Info "Pulling latest changes..."
        & git pull
        if ($LASTEXITCODE -ne 0) {
            throw "Git pull failed with exit code $LASTEXITCODE"
        }

        Write-Info "Building updated version..."
        $env:TAKARIK_ROOT = $TakarikDir
        & shards build --production
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed with exit code $LASTEXITCODE"
        }

        Set-Location $originalLocation
        Write-Success "Takarik has been updated successfully!"

        # Verify the build
        $executablePath = Join-Path $TakarikDir "bin\takarik.exe"
        if (-not (Test-Path $executablePath)) {
            $executablePath = Join-Path $TakarikDir "bin\takarik"
        }

        if (Test-Path $executablePath) {
            Write-Success "✅ Updated executable found: $executablePath"
        } else {
            Write-Warning "⚠️  Executable not found after update. Build may have failed."
        }

        exit 0
    } catch {
        Write-Error "Failed to update Takarik: $($_.Exception.Message)"
        if ($originalLocation) {
            Set-Location $originalLocation
        }
        exit 1
    }
}

Write-Info "Cloning Takarik repository to $TakarikDir..."

try {
    & git clone "https://github.com/takarik/takarik-cli" $TakarikDir
    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed with exit code $LASTEXITCODE"
    }
    Write-Success "Repository cloned successfully!"
} catch {
    Write-Error "Failed to clone Takarik repository: $($_.Exception.Message)"
    exit 1
}

Write-Info "Building Takarik..."
try {
    $originalLocation = Get-Location
    Set-Location $TakarikDir

    Write-Info "Installing dependencies..."
    $env:TAKARIK_ROOT = $TakarikDir
    & shards install
    if ($LASTEXITCODE -ne 0) {
        throw "Shards install failed with exit code $LASTEXITCODE"
    }

    Write-Info "Building in production mode..."
    & shards build --production
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed with exit code $LASTEXITCODE"
    }

    Set-Location $originalLocation
    Write-Success "Build completed successfully!"
} catch {
    Write-Error "Failed to build Takarik: $($_.Exception.Message)"
    if ($originalLocation) {
        Set-Location $originalLocation
    }
    exit 1
}

# Verify the build was successful
Write-Info "Verifying build..."
$executablePath = Join-Path $TakarikDir "bin\takarik.exe"
if (-not (Test-Path $executablePath)) {
    $executablePath = Join-Path $TakarikDir "bin\takarik"
}

if (-not (Test-Path $executablePath)) {
    Write-Error "Build verification failed: No executable found in bin directory"
    Write-Info "Contents of bin directory:"
    $binDir = Join-Path $TakarikDir "bin"
    if (Test-Path $binDir) {
        Get-ChildItem $binDir | Format-Table Name, Length
    } else {
        Write-Warning "Bin directory does not exist!"
    }
    exit 1
}

Write-Success "✅ Executable created: $executablePath"

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
Write-Info "Setting user environment variables..."
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
    Write-Warning "Could not set environment variables automatically: $($_.Exception.Message)"
    Write-Info "You may need to set them manually."
}

Write-Success "🎉 Takarik CLI has been installed successfully!"
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

Write-Info "Performing final verification..."
try {
    if (Test-Path "$TakarikDir\bin\takarik.exe") {
        $testBinary = "$TakarikDir\bin\takarik.exe"
        Write-Success "Installation verified - takarik.exe found!"
    } elseif (Test-Path "$TakarikDir\bin\takarik") {
        $testBinary = "$TakarikDir\bin\takarik"
        Write-Success "Installation verified - takarik binary found!"
    } else {
        Write-Warning "Warning: Could not find takarik executable in bin directory."
        Write-Info "This might be normal if the build created a different executable name."
        Write-Info "Check the contents of: $TakarikDir\bin\"
        Get-ChildItem "$TakarikDir\bin\" -ErrorAction SilentlyContinue
        exit 0
    }

    # Test the binary
    Write-Info "Testing takarik binary..."
    $testOutput = & $testBinary --version
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Takarik is working: $testOutput"
    } else {
        Write-Warning "⚠️  Takarik binary found but version test failed"
    }

} catch {
    Write-Warning "Could not verify installation: $($_.Exception.Message)"
}