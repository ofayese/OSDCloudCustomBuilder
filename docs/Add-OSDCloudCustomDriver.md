# Add-OSDCloudCustomDriver

## Synopsis

Adds and catalogs drivers for OSDCloud custom Windows images.

## Description

The `Add-OSDCloudCustomDriver` function copies driver packages to the OSDCloud workspace and creates a catalog file documenting the included drivers. It supports different levels of cataloging detail and validates driver paths before processing.

This function is essential for customizing OSDCloud deployments with specific hardware drivers that may not be included in the standard Windows installation media.

## Syntax

```powershell
Add-OSDCloudCustomDriver [-DriverPath] <String> [[-CatalogLevel] <String>] [[-WorkspacePath] <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## Parameters

| Name | Type | Position | Required | Description |
|------|------|----------|----------|-------------|
| DriverPath | String | 1 | Yes | The path to a driver package (.inf file) or directory containing multiple drivers |
| CatalogLevel | String | 2 | No | Specifies the level of detail for driver cataloging (Basic, Standard, Detailed) |
| WorkspacePath | String | 3 | No | The target OSDCloud workspace path. Defaults to current workspace |
| Force | Switch | Named | No | Forces the operation without confirmation prompts |
| WhatIf | Switch | Named | No | Shows what would happen if the command runs |
| Confirm | Switch | Named | No | Prompts for confirmation before executing |

## Examples

### Example 1: Add a single driver package

```powershell
Add-OSDCloudCustomDriver -DriverPath "C:\Drivers\NetworkAdapter\driver.inf"
```

Adds a single network adapter driver to the OSDCloud workspace with standard cataloging.

### Example 2: Add multiple drivers from a directory

```powershell
Add-OSDCloudCustomDriver -DriverPath "C:\Drivers\AllDrivers" -CatalogLevel "Detailed"
```

Adds all drivers from the specified directory with detailed cataloging information.

### Example 3: Add drivers with custom workspace

```powershell
Add-OSDCloudCustomDriver -DriverPath "C:\Drivers" -WorkspacePath "C:\OSDWorkspace" -Force
```

Adds drivers to a specific workspace without confirmation prompts.

## Notes

- Requires administrative privileges for driver installation
- Driver paths must exist and be accessible before execution
- Creates a driver catalog file for tracking included drivers
- Supports .inf driver packages and directory structures
- Compatible with Windows 10/11 deployment scenarios

## Related Links

- [New-OSDCloudCustomMedia](New-OSDCloudCustomMedia.md)
- [Test-OSDCloudCustomRequirements](Test-OSDCloudCustomRequirements.md)
- [OSDCloud Documentation](https://osdcloud.osdeploy.com/)
