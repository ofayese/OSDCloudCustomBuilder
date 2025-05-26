# Add-OSDCloudCustomScript

## Synopsis

Adds custom PowerShell scripts to OSDCloud deployment media.

## Description

The `Add-OSDCloudCustomScript` function integrates custom PowerShell scripts into the OSDCloud deployment process. Scripts can be executed at different phases of the deployment to customize the installation experience, configure settings, or install additional software.

This function provides a flexible way to extend OSDCloud deployments with organization-specific automation, configuration management, and post-installation tasks.

## Syntax

```powershell
Add-OSDCloudCustomScript [-ScriptPath] <String> [[-ScriptType] <String>] [-Force] [[-RunOrder] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## Parameters

| Name | Type | Position | Required | Description |
|------|------|----------|----------|-------------|
| ScriptPath | String | 1 | Yes | The path to the PowerShell script file (.ps1) to be added |
| ScriptType | String | 2 | No | Execution phase: Startup, Setup, or Customize (Default: Customize) |
| Force | Switch | Named | No | Forces overwrite of existing scripts without confirmation |
| RunOrder | String | 3 | No | Numeric value determining execution order (Default: 50) |
| WhatIf | Switch | Named | No | Shows what would happen if the command runs |
| Confirm | Switch | Named | No | Prompts for confirmation before executing |

## Examples

### Example 1: Add a basic customization script

```powershell
Add-OSDCloudCustomScript -ScriptPath "C:\Scripts\InstallApps.ps1"
```

Adds a script to install applications after Windows deployment completes.

### Example 2: Add a setup script with custom order

```powershell
Add-OSDCloudCustomScript -ScriptPath "C:\Scripts\ConfigureNetwork.ps1" -ScriptType Setup -RunOrder 10
```

Adds a network configuration script to run during Windows setup with high priority.

### Example 3: Add multiple scripts with ordering

```powershell
Add-OSDCloudCustomScript -ScriptPath "C:\Scripts\InstallDrivers.ps1" -RunOrder 20
Add-OSDCloudCustomScript -ScriptPath "C:\Scripts\ConfigureRegistry.ps1" -RunOrder 30
Add-OSDCloudCustomScript -ScriptPath "C:\Scripts\FinalCleanup.ps1" -RunOrder 90
```

Adds multiple scripts with specific execution order for a complete deployment workflow.

### Example 4: Force overwrite existing script

```powershell
Add-OSDCloudCustomScript -ScriptPath "C:\Scripts\UpdatedConfig.ps1" -Force
```

Overwrites an existing script without confirmation prompts.

## Notes

- Supports PowerShell (.ps1), Command (.cmd), and Batch (.bat) files
- Scripts are wrapped with error handling for PowerShell files
- Creates metadata files alongside scripts for tracking
- Requires valid OSDCloud workspace configuration
- Script execution order is determined by RunOrder parameter (lower numbers execute first)

## Script Types

- **Startup**: Executes during WinPE boot phase, before Windows installation
- **Setup**: Executes during Windows installation process
- **Customize**: Executes after Windows installation completes (Default)

## Related Links

- [New-OSDCloudCustomMedia](New-OSDCloudCustomMedia.md)
- [Add-OSDCloudCustomDriver](Add-OSDCloudCustomDriver.md)
- [Set-OSDCloudCustomSettings](Set-OSDCloudCustomSettings.md)
