# OSDCloudCustomBuilder

PowerShell module to build customized WinPE-based media for OSDCloud.

## Installation

```powershell
Import-Module ./src/OSDCloudCustomBuilder.psd1
```

## Example Usage

```powershell
New-OSDCloudCustomMedia -Path 'C:\MediaOutput'
```

## Commands

- `Add-OSDCloudCustomDriver`
- `Add-OSDCloudCustomScript`
- `New-OSDCloudCustomMedia`
