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

## Requirements

To use this development container, you need:

1. Docker Desktop with Windows container support enabled
2. Visual Studio Code with the Remote - Containers extension installed

## Usage

### Local Development

1. Ensure Docker Desktop is running in Windows containers mode
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
- Required PowerShell modules with minimum versions:
  - Pester 5.4.0+
  - PSScriptAnalyzer 1.21.0+
  - ThreadJob 2.0.3+
  - OSDCloud 23.5.26+
  - OSD 23.5.26+
- Required commands (git, DISM.exe)
- PowerShell 7.5.1 package availability
- Windows ADK and Windows PE add-on installation
- Workspace mounting
- Container diagnostics (Docker access, disk space)

### Important Notes

- The container uses process isolation (`--isolation=process`) for better performance
- The workspace is mounted at `C:/workspace` inside the container
- PowerShell modules installed in the container are separate from your host system

## Customization

If you need additional tools or PowerShell modules:

1. Edit the `Dockerfile` to add installation steps
2. Edit `devcontainer.json` to configure VS Code settings or extensions

## Troubleshooting

- If you encounter issues with Windows containers, ensure Hyper-V and Windows container features are enabled
- For permission issues, the container runs as `ContainerAdministrator`
- Docker Desktop must be configured to use Windows containers (not Linux containers)
