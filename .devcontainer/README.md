# Development Container for OSDCloudCustomBuilder

This directory contains configuration for a Windows-based development container that can be used with Visual Studio Code's Remote - Containers extension or GitHub Codespaces.

## Container Configuration

The development environment uses:

- Windows Server Core LTSC 2022 as the base image  
- PowerShell 7.5.1 as the default shell  
- Pre-installed tools:  
  - .NET SDKs (7.0 and 8.0) for building and running .NET-based components  
  - Windows ADK (Assessment and Deployment Kit) with Deployment Tools  
  - Windows PE add-on for the ADK  
  - Pester 5.7.1+ for testing  
  - PSScriptAnalyzer 1.24.0+ for code quality  
  - ThreadJob 2.0.3+ for parallel processing  
  - OSD 25.5.10.1+ module for deployment tasks  
  - OSDCloud 25.3.27.1+ module for cloud OS deployment  
  - PowerShell Pro Tools module (2025.2.0+) for script packaging  
  - ModuleBuilder 3.0.0+ for PowerShell module authoring and packaging  
  - Git (MinGit 2.40.0) for version control  
  - NuGet CLI for managing PowerShell packages

## Using with Visual Studio

Visual Studio 2022 (17.4+) supports dev containers. Open this project folder in Visual Studio, and you will be prompted to reopen it inside the dev container environment. Ensure Docker Desktop is running with Windows containers enabled. Once reopened, Visual Studio will build and connect to the container so you can develop and debug using the installed tools.

## Windows Container Requirements

To use this development container, you need:

1. **Windows 10/11** with Hyper-V and Containers features enabled (for Docker Desktop).  
2. **Docker Desktop** configured to use Windows containers.  

After cloning the repository, you can open it in VS Code and agree to reopen in the container. The Docker Compose setup will build the image (this may take some time on first run, as it downloads the Windows base image and installs the ADK and SDKs). Once the container is running, the **container-init.ps1** script will run automatically to update modules and run **test-environment.ps1**, verifying that all tools (ADK, .NET, modules, etc.) are properly installed.

You can then begin developing and testing PowerShell modules (including OSD/OSDCloud) inside the container using VS Code or Visual Studio. All the specified tools and modules are available, and you can run Pester tests, use PSScriptAnalyzer, and even package scripts using PowerShell Pro Tools within this isolated dev environment.
