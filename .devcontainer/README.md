# OSDCloudCustomBuilder Test Environment

This directory contains the configuration for a development container that provides a consistent test environment for OSDCloudCustomBuilder PowerShell module development.

## Overview

The dev container configuration:

1. Uses `mcr.microsoft.com/powershell/test-deps:lts-ubuntu-22.04` as the base image
2. Creates a multi-container environment using Docker Compose
3. Includes necessary PowerShell modules for testing (Pester, ThreadJob, PSScriptAnalyzer)
4. Provides a consistent development environment across different machines
5. Includes a comprehensive set of VS Code extensions for PowerShell and AI development

## Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop/) installed and running
- [Visual Studio Code](https://code.visualstudio.com/) with the [Remote Development extension pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)

## Getting Started

### Option 1: Using Visual Studio Code

1. Open the OSDCloudCustomBuilder repository folder in VS Code
2. When prompted, click "Reopen in Container" or use the command palette (F1) and select "Remote-Containers: Reopen in Container"
3. VS Code will build and start the dev container, then open the workspace inside it
4. You can now develop and test the module in a consistent environment

### Option 2: Using the Command Line

1. Navigate to the repository root directory
2. Run the bootstrap script:
   ```powershell
   ./start-test-environment.ps1
   ```
3. Connect to the running container:
   ```
   docker exec -it osdcloud-powershell pwsh
   ```
4. Run tests with:
   ```powershell
   ./Run-Tests.ps1
   ```

## Container Structure

- **PowerShell Container**: Based on `mcr.microsoft.com/powershell/test-deps:lts-ubuntu-22.04`, has all PowerShell testing dependencies installed
- **Shared Volumes**: The repository root is mounted at `/workspace` in the container
- **Environment Setup**: PowerShell modules needed for testing are automatically installed
- **Test Framework**: Pester 5.0+ is installed for running tests

## Included VS Code Extensions

This devcontainer comes with the following VS Code extensions pre-configured:

- **PowerShell Development**: PowerShell, Pester Test Explorer, PowerShell Pro Tools
- **AI Assistants**: GitHub Copilot, GitHub Copilot Chat, Cody AI, Claude Dev, DScodeGPT, Bito, TabNine
- **Docker**: Docker, Azure Tools for Docker 
- **Code Quality**: EditorConfig, IntelliCode, StyleLint
- **Testing**: Test Adapter Converter, Pester Test

## Running Tests

Inside the container, you can run tests using the included `Run-Tests.ps1` script:

```powershell
# Run basic tests
./Run-Tests.ps1

# Run tests with specialized test categories included
./Run-Tests.ps1 -IncludeSpecialized

# Run tests with code coverage reporting
./Run-Tests.ps1 -CodeCoverage
```

## Customizing the Environment

If you need to customize the development environment:

1. Edit the `.devcontainer/Dockerfile` to add additional tools or dependencies
2. Modify `.devcontainer/docker-compose.yml` to adjust container configuration or add more services
3. Update `.devcontainer/setup-test-environment.ps1` to add setup steps that should run when the container starts
4. Rebuild the container by running:
   ```powershell
   ./start-test-environment.ps1 -BuildContainer
   ```

## Troubleshooting

- **Container doesn't build**: Make sure Docker is running and you have permissions to build containers
- **PowerShell modules don't load**: Check the PSModulePath environment variable inside the container
- **Tests fail**: Ensure you have the correct module dependencies installed
- **Permission issues**: The container runs as the `vscode` user, which may not have permissions for certain operations

For more serious issues, you can rebuild the container from scratch:

```powershell
docker-compose -f .devcontainer/docker-compose.yml down
docker-compose -f .devcontainer/docker-compose.yml build --no-cache
docker-compose -f .devcontainer/docker-compose.yml up -d
```
