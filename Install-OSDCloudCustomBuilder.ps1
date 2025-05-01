<#
.SYNOPSIS
    Installs the OSDCloudCustomBuilder module to the PowerShell module path.
.DESCRIPTION
    This script copies the OSDCloudCustomBuilder module files to the user's PowerShell module path,
    making it available for import in any PowerShell session. It creates the module directory
    if it doesn't exist and handles the copying of all required files.
.NOTES
    Version: 1.0
    Author: Oluwaseun Fayese
    Date: April 19, 2025
#>

# Ensure any errors will stop execution
$ErrorActionPreference = 'Stop'

# Get the current script path
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleName = "OSDCloudCustomBuilder"

# Determine the module installation path
$moduleInstallPath = Join-Path -Path $env:PSModulePath.Split(';')[0] -ChildPath $moduleName

Write-Host "Installing $moduleName module to: $moduleInstallPath" -ForegroundColor Cyan

# Create the module directory if it doesn't exist
if (-not (Test-Path -Path $moduleInstallPath)) {
    Write-Host "Creating module directory..." -ForegroundColor Yellow
    New-Item -Path $moduleInstallPath -ItemType Directory -Force | Out-Null
}

# Copy all module files
Write-Host "Copying module files..." -ForegroundColor Yellow
$moduleFiles = @(
    "$scriptPath\$moduleName.psd1",
    "$scriptPath\$moduleName.psm1"
)

foreach ($file in $moduleFiles) {
    Copy-Item -Path $file -Destination $moduleInstallPath -Force
    Write-Host "  Copied: $file" -ForegroundColor Green
}

# Create directories
$directories = @("Private", "Public", "Shared")
foreach ($dir in $directories) {
    $sourcePath = Join-Path -Path $scriptPath -ChildPath $dir
    $destPath = Join-Path -Path $moduleInstallPath -ChildPath $dir
    
    if (Test-Path -Path $sourcePath) {
        if (-not (Test-Path -Path $destPath)) {
            New-Item -Path $destPath -ItemType Directory -Force | Out-Null
        }
        
        # Copy all files in the directory
        $files = Get-ChildItem -Path $sourcePath -File
        foreach ($file in $files) {
            Copy-Item -Path $file.FullName -Destination $destPath -Force
            Write-Host "  Copied: $($file.FullName)" -ForegroundColor Green
        }
    }
}

Write-Host "`nModule installation completed successfully!" -ForegroundColor Green
Write-Host "You can now use 'Import-Module $moduleName' in any PowerShell session." -ForegroundColor Green