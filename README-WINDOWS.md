# Takarik CLI - Windows Installation Guide

This guide provides Windows-specific installation instructions for Takarik CLI.

## Prerequisites

### Crystal Language
Takarik CLI requires Crystal language to be installed. Crystal on Windows is currently in **preview mode** but is functional for most use cases.

#### Option 1: Using Scoop (Recommended)
```powershell
# Install Scoop if you haven't already
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
iwr -useb get.scoop.sh | iex

# Add Crystal bucket and install
scoop bucket add crystal-preview https://github.com/neatorobito/scoop-crystal
scoop install crystal
```

#### Option 2: Direct Download
1. Visit the [Crystal Windows releases page](https://crystal-lang.org/install/on_windows/)
2. Download the appropriate installer for your system
3. Follow the installation wizard

### Required Tools
- **Git for Windows**: [Download here](https://git-scm.com/download/win)
- **Microsoft Visual C++ Build Tools** (usually comes with Crystal)
- **PowerShell 5.1+** (included with Windows)

## Installation

### Automated Installation (PowerShell)
Run this command in PowerShell as Administrator or with appropriate permissions:

```powershell
# Download and run the installer
iwr -useb https://raw.githubusercontent.com/takarik/takarik-cli/main/install.ps1 | iex
```

Or download the script first and run it:

```powershell
# Download the script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/takarik/takarik-cli/main/install.ps1" -OutFile "install.ps1"

# Run the installer
.\install.ps1
```

### Manual Installation

1. **Clone the repository:**
   ```powershell
   git clone https://github.com/takarik/takarik-cli %USERPROFILE%\.takarik
   cd %USERPROFILE%\.takarik
   ```

2. **Install dependencies and build:**
   ```powershell
   shards install
   shards build --production
   ```

3. **Add to PATH:**
   Add `%USERPROFILE%\.takarik\bin` to your system PATH environment variable.

## Usage

After installation, open a new PowerShell window and verify the installation:

```powershell
takarik --version
takarik --help
```

### Creating a New Project
```powershell
takarik new my-app .
cd my-app
shards install
```

### Using the Console
```powershell
takarik console
# or
takarik c
```

## Windows-Specific Notes

### File Paths
Takarik CLI uses Crystal's cross-platform file handling, so it should work correctly with Windows paths. However, some features may have different behavior on Windows:

- Console features may work differently due to terminal differences
- Some file operations might be slower due to Windows filesystem characteristics

### Performance
Crystal on Windows may have different performance characteristics compared to Unix systems. This is expected and will improve as Crystal's Windows support matures.

### Troubleshooting

#### Crystal Not Found
If you get "Crystal not found" errors:
1. Verify Crystal is installed: `crystal --version`
2. Check your PATH includes Crystal's bin directory
3. Restart your terminal/PowerShell session

#### Build Failures
If builds fail:
1. Ensure you have Microsoft Visual C++ Build Tools installed
2. Try running PowerShell as Administrator
3. Check that all dependencies are available

#### Permission Issues
If you encounter permission issues:
1. Run PowerShell as Administrator
2. Ensure your antivirus isn't blocking the installation
3. Try installing to a different directory

### Getting Help

- [Crystal Language Windows Documentation](https://crystal-lang.org/install/on_windows/)
- [Crystal Forum - Windows Support](https://forum.crystal-lang.org/c/help-support/11)
- [Takarik CLI Issues](https://github.com/takarik/takarik-cli/issues)

## Development on Windows

If you want to contribute to Takarik CLI development on Windows:

### Building from Source
```powershell
git clone https://github.com/takarik/takarik-cli
cd takarik-cli
shards install
shards build
```

### Running Tests
```powershell
crystal spec
```

### Using Cake Tasks
```powershell
cake build
cake clean
cake install
```

## Compatibility Status

| Feature | Windows Status | Notes |
|---------|----------------|-------|
| Basic CLI | ✅ Working | Full functionality |
| Project Creation | ✅ Working | Cross-platform templates |
| Console/REPL | ✅ Working | May have minor differences |
| Cake Integration | ✅ Working | Uses global cake command |
| File Operations | ✅ Working | Cross-platform paths |
| Build System | ✅ Working | Via shards/crystal |

## Known Limitations

1. **Crystal Preview**: Windows support in Crystal is still in preview
2. **Console Differences**: Interactive console may behave differently than on Unix systems
3. **Path Separators**: While handled automatically, some edge cases may exist
4. **Performance**: May be slower than Unix equivalents

## Future Improvements

As Crystal's Windows support improves, Takarik CLI will benefit from:
- Better performance
- More stable builds
- Enhanced console features
- Improved debugging capabilities

---

For the most up-to-date Windows compatibility information, check the [Crystal Windows documentation](https://crystal-lang.org/install/on_windows/).