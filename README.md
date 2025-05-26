# OSDCloudCustomBuilder

![Build Status](https://github.com/your-org/OSDCloudCustomBuilder/actions/workflows/ci.yml/badge.svg)
![PowerShell Gallery](https://img.shields.io/powershellgallery/v/OSDCloudCustomBuilder)
![License](https://img.shields.io/github/license/your-org/OSDCloudCustomBuilder)

A robust PowerShell module for automating and customizing OSDCloud deployments, drivers, scripts, and media creation.

## 🚀 Getting Started

### Prerequisites

- Windows PowerShell 5.1 or PowerShell 7+
- Administrator privileges for certain operations
- Visual Studio Code (recommended for development)

### Installation

Install the module from PowerShell Gallery:

```powershell
Install-Module -Name OSDCloudCustomBuilder -Scope CurrentUser -Force
```

Import the module:

```powershell
Import-Module OSDCloudCustomBuilder
```

### Quick Start

1. **Create custom OSD media:**
   ```powershell
   New-OSDCloudCustomMedia -MediaPath "C:\OSDMedia" -CustomDriverPath "C:\Drivers"
   ```

2. **Add custom drivers:**
   ```powershell
   Add-OSDCloudCustomDriver -DriverPath "C:\MyDrivers" -TargetPath "C:\OSDMedia"
   ```

3. **Test requirements:**
   ```powershell
   Test-OSDCloudCustomRequirements -Verbose
   ```

## 📦 Features

- **Driver Management**: Add and manage custom drivers for OSD deployments
- **Script Injection**: Include custom PowerShell scripts in deployment media
- **Media Customization**: Create and customize OSDCloud media with PowerShell 7
- **Telemetry Controls**: Enable/disable and configure deployment telemetry
- **Configuration Management**: Set and validate OSDCloud configuration settings
- **Testing & Validation**: Built-in requirement testing and validation
- **CI/CD Ready**: Fully tested with Pester and integrated build pipeline

## 🛠️ Development Setup

This project uses DevContainers to provide a consistent development environment:

1. Install [Visual Studio Code](https://code.visualstudio.com/)
2. Install the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
3. Clone this repository
4. Open the repository in VS Code
5. When prompted, click "Reopen in Container"

### Development Workflow

- **Build the module**: `./build.ps1 Build`
- **Run tests**: `./build.ps1 Test`
- **Analyze code**: `./build.ps1 Analyze`
- **Generate documentation**: `./build.ps1 Docs`

### Project Structure

See the [Project Structure](docs/ProjectStructure.md) documentation for more details on the module organization.
- **Analyze code**: `./build.ps1 Analyze`
- **Generate documentation**: `./build.ps1 Docs`
- **Clean build artifacts**: `./build.ps1 Clean`

## 📁 Project Structure

```
├── Public/           # Public functions (exported)
├── Private/          # Private functions (internal)
├── Shared/           # Shared utilities
├── tests/            # Pester tests
├── docs/             # Documentation (generated)
├── .devcontainer/    # Development container configuration
└── build.ps1         # Build script
```

## 📖 Function Reference

| Function | Purpose |
|----------|---------|
| `Add-OSDCloudCustomDriver` | Add custom drivers to OSD media |
| `Add-OSDCloudCustomScript` | Add custom scripts to deployment |
| `New-CustomOSDCloudISO` | Create custom OSD ISO images |
| `New-OSDCloudCustomMedia` | Create custom OSD media |
| `Set-OSDCloudCustomSettings` | Configure OSD settings |
| `Test-OSDCloudCustomRequirements` | Validate system requirements |
| `Update-CustomWimWithPwsh7` | Update WIM with PowerShell 7 |

See [docs/functions](docs/functions) for detailed function documentation.

## 🧪 Testing

Run all tests:

```powershell
./build.ps1 Test
```

Run specific test files:

```powershell
Invoke-Pester -Path ./tests/New-OSDCloudCustomMedia.Tests.ps1
```

## 📊 Version

This project adheres to [Semantic Versioning](https://semver.org/).

Current version information can be found in `OSDCloudCustomBuilder.psd1`.

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 🔗 Related Links

- [OSDCloud Documentation](https://osdcloud.osdeploy.com/)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [Keep a Changelog](https://keepachangelog.com/)
