# Project Structure

## Overview

OSDCloudCustomBuilder follows a standard PowerShell module structure with clearly defined responsibilities for different directories.

## Directory Structure

```
OSDCloudCustomBuilder/
│
├── Public/                 # Public functions (exported)
│   ├── Add-OSDCloudCustomDriver.ps1
│   ├── Add-OSDCloudCustomScript.ps1
│   └── ...
│
├── Private/                # Private functions (for internal use only)
│   ├── Copy-CustomWimToWorkspace.ps1
│   ├── Get-PowerShell7Package.ps1
│   └── ...
│
├── Shared/                 # Shared utilities used by both public and private functions
│   ├── SharedUtilities.ps1
│   └── SharedUtilities.psm1
│
├── docs/                   # Documentation files
│   ├── Add-OSDCloudCustomDriver.md
│   ├── Add-OSDCloudCustomScript.md
│   └── ...
│
├── tests/                  # Pester test files
│   ├── All-PublicFunctions.Tests.ps1
│   ├── New-OSDCloudCustomMedia.Tests.ps1
│   └── ...
│
└── tools/                  # Development and maintenance scripts
    ├── New-ModuleScaffold.ps1
    └── Publish-Module.ps1
```

## Core Files

- **OSDCloudCustomBuilder.psd1**: Module manifest file that defines metadata and exports
- **OSDCloudCustomBuilder.psm1**: Main module script that loads all function files
- **build.ps1**: Build script for testing, analyzing, and packaging
- **Invoke-Build.ps1**: Comprehensive build automation script
- **config.json**: Module configuration settings
- **PSScriptAnalyzer.settings.psd1**: Code style settings

## Development Workflow

1. Add new functions to the appropriate directory (Public or Private)
2. Run `./build.ps1 Test` to validate changes
3. Run `./build.ps1 Analyze` to ensure code quality
4. Run `./build.ps1 Docs` to update documentation
5. Update `OSDCloudCustomBuilder.psd1` to export any new public functions

## Testing

Tests are located in the `tests` directory and follow the Pester framework structure. Test files should be named to match the function they test.
