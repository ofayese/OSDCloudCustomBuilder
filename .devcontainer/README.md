# Development Container for OSDCloudCustomBuilder

This directory contains configuration for a Windows-based development container that can be used with Visual Studio Code's Remote - Containers extension or GitHub Codespaces.

## Container Configuration

The development environment uses:

- Windows Server Core LTSC 2022 as the base image
- PowerShell 7.5.1 as the default shell
- Pre-installed tools:
  - Pester 5.4.0+ for testing
  - PSScriptAnalyzer 1.21.0+ for code quality
  - ThreadJob 2.0.3+ for parallel processing
  - OSDCloud 23.5.26+ module for integration testing
  - OSD 23.5.26+ module for deployment tasks
  - Windows ADK (Assessment and Deployment Kit)
  - Windows PE add-on for ADK
  - PowerShell 7.5.1 package for testing PowerShell 7 integration
  - DISM and Windows deployment tools
  - Git for version control

## Windows Container Requirements

To use this development container, you need:

1. Windows 10/11 with Hyper-V and Containers features enabled
2. Docker Desktop for Windows configured for Windows containers
3. Visual Studio Code with the Remote - Containers extension installed

## Usage

### Local Development

1. **Ensure Docker Desktop is running in Windows containers mode**:
   - Right-click the Docker icon in the system tray
   - Select "Switch to Windows containers..." if currently in Linux mode
2. Open this repository in VS Code
3. When prompted, click "Reopen in Container" or run the "Remote-Containers: Reopen in Container" command
4. VS Code will build the container and connect to it
5. The test-environment.ps1 script will run automatically to verify the container setup

### Verifying the Environment

The container includes a verification script that checks if all required tools and modules are available:

```powershell
# Run this to verify the container setup
./devcontainer/test-environment.ps1
```

This script checks for:
- Required PowerShell modules with minimum versions
- Required commands (git, DISM.exe)
- PowerShell 7.5.1 package availability
- Windows ADK and Windows PE add-on installation
- Workspace mounting
- Container diagnostics (Docker access, disk space)

### Important Notes

- The container uses process isolation (`isolation: process`) for better performance
- The workspace is mounted at `C:/workspace` inside the container
- PowerShell modules installed in the container are separate from your host system
- Container runs as `ContainerAdministrator` for full access to Windows features

## Troubleshooting Windows Containers

- **"Docker Desktop service not running"** - Start the Docker Desktop service
- **"Hardware assisted virtualization is not enabled"** - Enable virtualization in BIOS/UEFI
- **"Docker is not configured for Windows containers"** - Right-click the Docker icon and select "Switch to Windows containers..."
- **Container fails to start** - Ensure you have sufficient memory (4GB allocated in docker-compose.yml)
- **Network connectivity issues** - The container uses NAT networking by default
- **Missing tools** - Check the test-environment.ps1 output for any missing components

## Performance Considerations

- Windows containers can be resource-intensive
- Process isolation is used for better performance compared to Hyper-V isolation
- If the build process is slow, consider increasing the memory limit in docker-compose.yml
