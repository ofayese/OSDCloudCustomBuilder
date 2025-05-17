# PowerShell OSDCloud Development Container

This development container provides a consistent environment for PowerShell module development, testing, and OSDCloud image building.

## Features

- Windows Server 2022 base image
- PowerShell 7
- Windows ADK with WinPE add-on
- Git, .NET SDK, and other development tools
- Pre-installed PowerShell modules:
  - OSD (for OSDCloud functionality)
  - Pester (testing framework)
  - PSScriptAnalyzer (static code analysis)
  - InvokeBuild (build automation)
  - BuildHelpers (CI/CD helpers)
  - Plaster (scaffolding)
  - platyPS (documentation generation)
  - PSDeploy (deployment automation)
  - PSCodeHealth (code quality metrics)
  - ModuleBuilder (module building and packaging)
- VS Code integration with recommended extensions
- Templates for module development, build scripts, and CI/CD workflows

## Getting Started

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
2. Install [VS Code](https://code.visualstudio.com/)
3. Install the [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension for VS Code
4. Clone your repository and open it in VS Code
5. When prompted, click "Reopen in Container" or run the "Remote-Containers: Reopen in Container" command from the Command Palette (F1)

## Container Structure

- `.devcontainer/Dockerfile`: Defines the container image
- `.devcontainer/devcontainer.json`: Configures VS Code integration
- `.devcontainer/scripts/`: Contains setup scripts for the container

## Development Workflow

### PowerShell Module Development

The container includes several tools and templates to streamline PowerShell module development:

1. Use `New-ModuleProject` function to scaffold a new module
2. Write your module code in the `Source` directory
3. Write tests in the `Tests` directory
4. Use `Invoke-Build` to build, test, and analyze your module
5. Use `platyPS` to generate documentation

### OSDCloud Image Building

The container includes the OSD module for building OSDCloud images:

1. Use `New-OSDCloudISO` function to create a new OSDCloud ISO
2. Customize the ISO as needed
3. Test the ISO in a virtual machine

## VS Code Integration

The container comes with pre-configured VS Code settings and extensions:

- PowerShell extension for IntelliSense and debugging
- Markdown support for documentation
- Git integration
- Docker integration
- Code spell checker

## Custom Functions

The PowerShell profile includes several custom functions:

- `Start-ModuleBuild`: Run the build process
- `Start-ModuleTest`: Run Pester tests
- `Start-CodeAnalysis`: Run PSScriptAnalyzer
- `New-ModuleProject`: Create a new module project
- `New-OSDCloudISO`: Create a new OSDCloud ISO

## Templates

The container includes templates for:

- Build scripts
- GitHub Actions workflows
- VS Code tasks
- Module manifests

## Troubleshooting

If you encounter issues with the container:

1. Check the Docker logs for errors
2. Verify that Docker has enough resources allocated
3. Try rebuilding the container with `Remote-Containers: Rebuild Container`
4. Check the setup scripts in `.devcontainer/scripts/` for errors

## Contributing

Feel free to customize this container to suit your specific needs. If you make improvements, consider contributing them back to the original repository.
