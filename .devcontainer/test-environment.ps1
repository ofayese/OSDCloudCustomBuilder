#!/usr/bin/env pwsh
#Requires -Version 7.5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$requiredModules = @{
    'Pester'                = '5.7.1'
    'PSScriptAnalyzer'      = '1.24.0'
    'ThreadJob'             = '2.0.3'
    'OSDCloud'              = '25.3.27.1'
    'OSD'                   = '25.5.10.1'
    'OSDCloudCustomBuilder' = '0.3.1'
    'ModuleBuilder'         = '3.0.0'
    'PowerShellProTools'    = '2025.2.0'
}

function Write-Section {
    param([string]$Title)
    Write-Information ""
    Write-Information ("━" * 79)
    Write-Information "➤ $Title"
    Write-Information ("━" * 79)
}

function Test-CommandAvailable {
    param([string]$Command)
    return ($null -ne (Get-Command -Name $Command -ErrorAction SilentlyContinue))
}

function Test-ModuleVersion {
    param(
        [string]$ModuleName,
        [string]$MinimumVersion
    )
    $module = Get-Module -Name $ModuleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $module) {
        Write-Error "$ModuleName is not installed!"
        return $false
    }
    if ($module.Version -lt (New-Object Version $MinimumVersion)) {
        Write-Error "$ModuleName is below required version $MinimumVersion (found $($module.Version))"
        return $false
    }
    Write-Information "✅ $ModuleName (v$($module.Version)) is installed and meets minimum version $MinimumVersion"
    return $true
}

# Check basic environment and required commands
$requiredCommands = @("git")
if ($isWindowsPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) { 
    $requiredCommands += @("DISM.exe", "dotnet") 
}
$allCommandsOK = $true
foreach ($cmd in $requiredCommands) {
    if (Test-CommandAvailable -Command $cmd) {
        Write-Information "✅ $cmd found at: $((Get-Command $cmd).Source)"
    }
    else {
        Write-Warning "⚠️ $cmd is not available!"
        $allCommandsOK = $false
    }
}

# Verify required PowerShell modules are installed at or above required versions
Write-Section "Checking PowerShell Modules"
$allModulesOK = $true
foreach ($module in $requiredModules.GetEnumerator()) {
    if (-not (Test-ModuleVersion -ModuleName $module.Key -MinimumVersion $module.Value)) {
        $allModulesOK = $false
    }
}

# Platform-specific environment checks
if ($isWindowsPlatform) {
    Write-Section "Windows Platform Checks"
    # Verify Windows ADK components
    if (Test-Path "C:\ADK\Assessment and Deployment Kit\Deployment Tools") {
        Write-Information "✅ Windows ADK Deployment Tools are installed."
    }
    else {
        Write-Error "Windows ADK Deployment Tools not found!"
        $allCommandsOK = $false
    }
    if (Test-Path "C:\ADK\Assessment and Deployment Kit\Windows Preinstallation Environment") {
        Write-Information "✅ Windows PE add-on is installed."
    }
    else {
        Write-Error "Windows PE add-on not found!"
        $allCommandsOK = $false
    }
    # List installed .NET SDKs
    if (Test-CommandAvailable "dotnet") {
        $sdkList = & dotnet --list-sdks
        if ($sdkList) {
            Write-Information "Installed .NET SDKs:`n$($sdkList -join "`n")"
        }
    }
} else {
    Write-Section "Non-Windows Platform Checks"
    if (Test-CommandAvailable "df") {
        $diskInfo = (& df -h / | Select-Object -Skip 1)
        Write-Information "Disk Info: $diskInfo"
    }
    else {
        Write-Warning "⚠️ 'df' command not found."
    }
}

Write-Section "Environment Verification Results"
# Final evaluation: combine all checks
$final = $allModulesOK -and $allCommandsOK
if ($isWindowsPlatform) {
    $final = $final -and (Test-CommandAvailable "DISM.exe")
}
if ($final) {
    Write-Information "✅ Environment is fully configured and all checks passed."
} else {
    Write-Error "❌ Some environment checks failed. Please review the warnings/errors above."
    exit 1
}
