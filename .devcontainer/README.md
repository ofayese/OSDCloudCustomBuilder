# OSDCloudCustomBuilder DevContainer

This directory contains a comprehensive development container configuration for the OSDCloudCustomBuilder project. The devcontainer provides a fully configured environment for PowerShell module development, .NET development, and comprehensive testing.

## 🚀 Features

### Development Environment

- **PowerShell 7.x** - Latest PowerShell with enhanced features
- **.NET SDK 8.0** - With backward compatibility for 6.0 and 7.0
- **Ubuntu 22.04** - Stable and well-supported base image
- **VS Code Extensions** - Comprehensive set of development extensions

### Testing & Quality Assurance
- **Pester 5.x** - Modern PowerShell testing framework
- **PSScriptAnalyzer** - Static code analysis
- **Code Coverage** - Integrated coverage reporting
- **Automated Quality Gates** - Pre-commit hooks and CI/CD support

### Build & Automation
- **InvokeBuild** - Advanced build automation
- **ModuleBuilder** - PowerShell module packaging
- **dotnet CLI** - .NET project management
- **Git Hooks** - Automated quality checks

### Development Tools
- **GitHub CLI** - Repository management
- **Azure CLI** - Cloud development support
- **Docker CLI** - Container development
- **Multiple Shell Options** - bash, zsh, PowerShell

## 📁 File Structure

```
.devcontainer/
├── devcontainer.json      # Main configuration with features and settings
├── Dockerfile            # Multi-stage container build
├── postCreate.sh         # Post-creation setup script
├── devsetup.ps1          # PowerShell module installation
├── ubuntutools.sh        # Ubuntu tools and utilities
├── cache/                # Persistent cache directory
└── README.md             # This file
```

## 🔧 Configuration Details

### devcontainer.json
- Uses VS Code dev container features for .NET, Git, GitHub CLI, and PowerShell
- Configures comprehensive VS Code settings for PowerShell and .NET development
- Includes 20+ carefully selected extensions
- Sets up persistent cache mounting
- Configures post-creation and post-start commands

### Dockerfile
- Multi-stage build based on Ubuntu 22.04
- Installs .NET SDK 8.0 with backward compatibility
- Includes PowerShell 7.x from Microsoft repositories
- Sets up non-root user (vscode) for security
- Installs comprehensive development tooling
- Configures PowerShell modules with specific versions

### Post-Creation Setup (postCreate.sh)
- Restores .NET dependencies
- Installs PowerShell modules from requirements.psd1
- Creates enhanced PowerShell profile
- Sets up VS Code tasks and launch configurations
- Configures Git hooks for quality assurance
- Creates test coverage configuration

## 🛠️ PowerShell Modules Included

### Testing & Quality
- **Pester 5.5.0** - Testing framework
- **PSScriptAnalyzer 1.21.0** - Code analysis
- **PSRule 2.9.0** - Rule-based validation
- **PSRule.Rules.Azure 1.30.1** - Azure validation

### Development Tools
- **InvokeBuild 5.10.4** - Build automation
- **ModuleBuilder 2.0.0** - Module packaging
- **PSModuleDevelopment 2.2.9.94** - Development tools
- **Plaster 1.1.3** - Project templating

### Framework & Utilities
- **PSFramework 1.7.270** - Logging and utilities
- **PSDepend 0.3.8** - Dependency management
- **PSReadLine 2.3.4** - Enhanced command line
- **PowerShellGet 2.2.5** - Package management

### Domain-Specific
- **OSD 23.5.26.1** - OS deployment automation
- **PowerShellProTools 5.8.6** - Professional tools

## 🚀 Quick Start

1. **Open in VS Code**: Click "Reopen in Container" when prompted
2. **Wait for Setup**: Initial build takes 5-10 minutes
3. **Open PowerShell Terminal**: `Ctrl+Shift+` (backtick)
4. **Verify Setup**: Run `Show-DevEnvironment`
5. **Start Developing**: Use provided functions and tasks

## 💡 Available Commands

### PowerShell Functions
```powershell
Show-DevEnvironment      # Display environment status
Test-ModuleStructure     # Validate module structure
Start-DevTest           # Run comprehensive tests
Start-DevTest -Coverage # Run tests with coverage
Invoke-FullBuild        # Build entire project
Invoke-FullTest         # Complete test suite
```

### VS Code Tasks
- **Build: Full Project** - Complete build process
- **Test: Full Test Suite** - All tests with coverage
- **Test: Pester Only** - PowerShell tests only
- **Analyze: PSScriptAnalyzer** - Code analysis
- **Build: .NET Only** - .NET project build
- **Test: .NET Only** - .NET tests only
- **Clean: All Artifacts** - Remove build outputs

### Shell Aliases
```bash
# Git shortcuts
gs      # git status
ga      # git add
gc      # git commit
gp      # git push

# .NET shortcuts
dr      # dotnet run
db      # dotnet build
dt      # dotnet test

# PowerShell shortcuts
ps      # pwsh
pester  # pwsh -Command Invoke-Pester
analyze # pwsh -Command Invoke-ScriptAnalyzer
```

## 🔍 Testing Strategy

### Unit Tests
- **Pester Tests** - Located in `./tests/`
- **Coverage Analysis** - Automatic code coverage
- **Mock Support** - Comprehensive mocking capabilities

### Integration Tests
- **Module Loading** - Verify module imports
- **Function Validation** - End-to-end function testing
- **Configuration Testing** - Settings validation

### Quality Assurance
- **PSScriptAnalyzer** - Static code analysis
- **Pre-commit Hooks** - Automated quality gates
- **Continuous Integration** - Ready for CI/CD pipelines

## 📊 Monitoring & Debugging

### Code Coverage
- **Coverlet** - .NET code coverage
- **Pester Coverage** - PowerShell code coverage
- **ReportGenerator** - Coverage report generation
- **VS Code Integration** - Coverage gutters

### Debugging
- **PowerShell Debugger** - Integrated debugging
- **Breakpoint Support** - Full breakpoint functionality
- **Variable Inspection** - Runtime variable analysis
- **.NET Debugging** - CoreCLR debugging support

## 🔒 Security & Best Practices

### Security
- **Non-root User** - vscode user for development
- **Least Privilege** - Minimal required permissions
- **Secure Defaults** - Security-focused configurations

### Best Practices
- **Version Pinning** - Specific module versions
- **Clean Separation** - Clear separation of concerns
- **Documentation** - Comprehensive inline documentation
- **Error Handling** - Robust error handling patterns

## 🚀 Performance Optimizations

### Caching
- **Persistent Cache** - `.devcontainer/cache` mounting
- **Module Cache** - PowerShell module caching
- **Build Cache** - .NET build artifact caching

### Resource Management
- **Optimized Images** - Multi-stage Docker builds
- **Selective Installation** - Only required components
- **Cleanup Processes** - Automated cleanup procedures

## 🔧 Customization

### Adding Modules
Edit `devsetup.ps1` to add PowerShell modules:
```powershell
$RequiredModules += @{
    Name = "ModuleName"
    Version = "1.0.0"
    Description = "Module description"
    Category = "CategoryName"
}
```

### Adding Tools
Edit `ubuntutools.sh` to add system tools:
```bash
sudo apt install -y new-tool
```

### VS Code Extensions
Edit `devcontainer.json` extensions array:
```json
"extensions": [
    "publisher.extension-name"
]
```

## 🐛 Troubleshooting

### Common Issues

#### Container Build Fails
- Check Docker daemon is running
- Verify network connectivity
- Clear Docker cache: `docker system prune -a`

#### PowerShell Module Issues
- Verify PSGallery connectivity
- Check module versions in `devsetup.ps1`
- Clear PowerShell cache: `Clear-PackageCache`

#### Performance Issues
- Increase Docker memory allocation
- Use WSL 2 backend on Windows
- Enable Docker BuildKit

### Debug Commands
```bash
# Check container logs
docker logs <container-id>

# Inspect container
docker exec -it <container-id> bash

# Verify PowerShell
pwsh -Command Get-Module -ListAvailable

# Verify .NET
dotnet --info
```

## 📚 Additional Resources

- [VS Code Dev Containers](https://code.visualstudio.com/docs/remote/containers)
- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [.NET Documentation](https://docs.microsoft.com/dotnet/)
- [Pester Documentation](https://pester.dev/)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)

## 🤝 Contributing

When contributing to the devcontainer configuration:

1. Test changes thoroughly
2. Update documentation
3. Verify cross-platform compatibility
4. Follow security best practices
5. Maintain backward compatibility

## 📝 License

This devcontainer configuration is part of the OSDCloudCustomBuilder project and follows the same licensing terms.
