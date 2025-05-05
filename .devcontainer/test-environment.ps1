#!/usr/bin/env pwsh
#Requires -Version 7.0

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# Set of required modules with minimum versions
$requiredModules = @{
    'Pester'          = '5.4.0'
    'PSScriptAnalyzer' = '1.21.0'
    'ThreadJob'       = '2.0.3'
    'OSDCloud'        = '23.5.26'
    'OSD'             = '23.5.26'
}

# Function to display section headers
function Write-Section {
    param([string]$Title)
    Write-Information ""
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "➤ $Title"
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

function Test-CommandAvailable {
    param([string]$Command)

    $null -ne (Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

function Test-ModuleVersion {
    param(
        [string]$ModuleName,
        [string]$MinimumVersion
    )

    $module = Get-Module -Name $ModuleName -ListAvailable |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1

    if ($null -eq $module) {
        Write-Error "❌ Module not found: $ModuleName"
        return $false
    }

    $minVersion = [version]$MinimumVersion
    $installedVersion = $module.Version

    if ($installedVersion -ge $minVersion) {
        Write-Information "✅ $ModuleName $installedVersion (required: $MinimumVersion)"
        return $true
    } else {
        Write-Error "❌ $ModuleName version $installedVersion is below required version $MinimumVersion"
        return $false
    }
}

# Check PowerShell version
Write-Section "Checking PowerShell Version"
$PSVersionTable | Format-Table -Property PSVersion, PSEdition, Platform, OS

# Check workspace
Write-Section "Checking Workspace"
if (Test-Path -Path "/workspace") {
    Write-Information "✅ /workspace directory is mounted"
    Get-Item -Path "/workspace" | Format-Table -Property Mode, LastWriteTime, Length, Name
} else {
    Write-Error "❌ /workspace directory is not mounted correctly"
}

# Check for required modules
Write-Section "Checking PowerShell Modules"
$allModulesOK = $true
foreach ($module in $requiredModules.GetEnumerator()) {
    $moduleOK = Test-ModuleVersion -ModuleName $module.Key -MinimumVersion $module.Value
    $allModulesOK = $allModulesOK -and $moduleOK
}

if ($allModulesOK) {
    Write-Information "✅ All required PowerShell modules are installed with correct versions"
} else {
    Write-Error "❌ Some required PowerShell modules are missing or have incorrect versions"
}

# Check for required commands
Write-Section "Checking Required Commands"
$requiredCommands = @('git', 'DISM.exe')
$allCommandsOK = $true

foreach ($command in $requiredCommands) {
    if (Test-CommandAvailable -Command $command) {
        $commandPath = (Get-Command -Name $command).Source
        Write-Information "✅ $command is available: $commandPath"
    } else {
        Write-Error "❌ $command is not available"
        $allCommandsOK = $false
    }
}

# Check Windows ADK and Windows PE add-on
Write-Section "Checking Windows ADK and Windows PE"
$adkComponents = @(
    "C:\ADK\Assessment and Deployment Kit\Deployment Tools\amd64\DISM"
)

$allComponentsOK = $true
foreach ($component in $adkComponents) {
    if (Test-Path -Path $component) {
        Write-Information "✅ ADK component found: $component"
    } else {
        Write-Error "❌ ADK component missing: $component"
        $allComponentsOK = $false
    }
}

# Container diagnostics
Write-Section "Container Diagnostics"
$diskSpace = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -eq "C:\" } |
    Select-Object -Property Name, Used, Free, @{Name="FreeGB";Expression={[math]::Round($_.Free / 1GB, 2)}}

Write-Information "Available disk space on C: drive: $($diskSpace.FreeGB) GB"

# Final status
Write-Section "Environment Verification Results"
if ($allModulesOK -and $allCommandsOK -and $allComponentsOK) {
    Write-Information "✅ Development container is properly configured for OSDCloud development"
} else {
    Write-Error "❌ Development container has configuration issues that need to be addressed"
}
