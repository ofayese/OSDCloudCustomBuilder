#!/usr/bin/env pwsh
#Requires -Version 7.5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$requiredModules = @{
    'Pester'                = '5.4.0'
    'PSScriptAnalyzer'      = '1.21.0'
    'ThreadJob'             = '2.0.3'
    'OSDCloud'              = '23.5.26'
    'OSD'                   = '23.5.26'
    'OSDCloudCustomBuilder' = '0.0.1'
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
    $module = Get-Module -Name $ModuleName -ListAvailable |
    Sort-Object Version -Descending |
    Select-Object -First 1

    if (-not $module) {
        Write-Error "❌ Module not found: $ModuleName"
        return $false
    }

    if ($module.Version -ge [version]$MinimumVersion) {
        Write-Information "✅ $ModuleName $($module.Version) (required: $MinimumVersion)"
        return $true
    }
    else {
        Write-Error "❌ $ModuleName version $($module.Version) is below required $MinimumVersion"
        return $false
    }
}

function Test-IsWindowsPlatform {
    return [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
}

function Test-PathExists {
    param(
        [string]$Path,
        [switch]$AllowForwardSlash
    )

    if (Test-Path -Path $Path) {
        return $true
    }

    if ($AllowForwardSlash) {
        $alt1 = $Path -replace '/', '\'
        $alt2 = $Path -replace '\\', '/'
        return (Test-Path $alt1 -or Test-Path $alt2)
    }

    return $false
}

# ----- Begin Script Execution -----

Write-Section "Checking PowerShell Version"
$PSVersionTable | Format-Table -AutoSize

Write-Section "Checking Current User"
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Information "Current user: $currentUser"
if ($currentUser -like "*ContainerAdministrator*") {
    Write-Information "✅ Running as ContainerAdministrator"
}
else {
    Write-Warning "⚠️ Not running as ContainerAdministrator (current: $currentUser)"
}

$isWindowsPlatform = Test-IsWindowsPlatform
Write-Information "Running on Windows platform: $isWindowsPlatform"

Write-Section "Checking Workspace"
$workspaceFound = $false

try {
    if (Test-Path "/workspace") {
        $workspaceFound = $true
        Write-Information "✅ Workspace mounted at: /workspace"
        Get-Item -Path "/workspace" | Format-Table -Property Mode, LastWriteTime, Length, Name
    }
    else {
        $envPaths = @($env:WORKSPACE, $env:USERPROFILE, $env:TEMP, $env:ProgramData)
        foreach ($base in $envPaths) {
            if ($base -and (Test-Path $base)) {
                $candidate = Join-Path $base "workspace"
                if (Test-Path $candidate) {
                    $workspaceFound = $true
                    Write-Information "✅ Workspace found at: $candidate"
                    Get-Item $candidate | Format-Table Mode, LastWriteTime, Length, Name
                    break
                }
            }
        }
        if (-not $workspaceFound) {
            Write-Error "❌ Workspace not found in expected locations."
            Write-Information "Available drives: $((Get-PSDrive -PSProvider FileSystem).Name -join ', ')"
        }
    }
}
catch {
    Write-Error "❌ Error checking workspace: $_"
}

Write-Section "Checking PSModulePath"
$env:PSModulePath -split [IO.Path]::PathSeparator | ForEach-Object {
    Write-Information "  - $_"
}

Write-Information "Checking for expected module paths..."
$pathFlags = @{
    'Workspace'         = $false
    'PowerShellCore'    = $false
    'WindowsPowerShell' = $false
}

foreach ($path in ($env:PSModulePath -split [IO.Path]::PathSeparator)) {
    if ($path -match "workspace.*Modules") { $pathFlags['Workspace'] = $true }
    elseif ($path -match "PowerShell.*Modules") { $pathFlags['PowerShellCore'] = $true }
    elseif ($path -match "WindowsPowerShell.*Modules") { $pathFlags['WindowsPowerShell'] = $true }
}

foreach ($key in $pathFlags.Keys) {
    if ($pathFlags[$key]) {
        Write-Information "✅ Found $key module path"
    }
    else {
        Write-Warning "⚠️ $key module path missing"
    }
}

Write-Section "Checking PowerShell Modules"
$allModulesOK = $true
foreach ($module in $requiredModules.GetEnumerator()) {
    if (-not (Test-ModuleVersion -ModuleName $module.Key -MinimumVersion $module.Value)) {
        $allModulesOK = $false
    }
}

Write-Section "Checking Required Commands"
$requiredCommands = @("git")
if ($isWindowsPlatform) { $requiredCommands += "DISM.exe" }

$allCommandsOK = $true
foreach ($cmd in $requiredCommands) {
    if (Test-CommandAvailable -Command $cmd) {
        Write-Information "✅ $cmd found at: $((Get-Command $cmd).Source)"
    }
    else {
        Write-Error "❌ Required command not found: $cmd"
        $allCommandsOK = $false
    }
}

if ($isWindowsPlatform) {
    Write-Section "Checking DISM Path in Environment"
    if (Test-CommandAvailable "DISM.exe") {
        Write-Information "✅ DISM.exe available in PATH"
    }
    else {
        Write-Warning "⚠️ DISM.exe not found or not in PATH"
    }

    Write-Section "Checking Windows ADK"
    if (Test-CommandAvailable "DISM.exe") {
        Write-Information "✅ ADK Deployment Tools (DISM.exe) available"
    }
    else {
        Write-Error "❌ ADK tools missing"
    }
    Write-Information "ℹ️ Skipping Windows PE check - please verify manually"
}
else {
    Write-Section "Non-Windows Platform Checks"
    Write-Information "⚠️ Skipping DISM and ADK checks on non-Windows"
    if (Test-CommandAvailable "df") {
        $diskInfo = (& df -h / | Select-Object -Skip 1)
        Write-Information "Disk Info: $diskInfo"
    }
    else {
        Write-Warning "⚠️ 'df' command not available for disk space check"
    }
}

Write-Section "Testing Network Connectivity"
$urls = @("https://www.github.com", "https://www.powershellgallery.com")
foreach ($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 5
        Write-Information "✅ $url is reachable (Status: $($response.StatusCode))"
    }
    catch {
        Write-Error "❌ Cannot reach $url : $_"
    }
}

Write-Section "Security Configuration"
$tls = [Net.ServicePointManager]::SecurityProtocol
Write-Information "Current TLS: $tls"
if ($tls -band [Net.SecurityProtocolType]::Tls12) {
    Write-Information "✅ TLS 1.2 enabled"
}
else {
    Write-Warning "⚠️ TLS 1.2 may not be enabled — consider enabling for PowerShell Gallery"
}

Write-Section "Environment Verification Results"
$final = $allModulesOK -and $allCommandsOK
if ($isWindowsPlatform) {
    $final = $final -and (Test-CommandAvailable "DISM.exe")
}

if ($final) {
    Write-Information "✅ Environment is fully configured for OSDCloud development"
}
else {
    Write-Error "❌ Environment has configuration issues to resolve"
}
