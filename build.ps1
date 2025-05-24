# build.ps1 - Entry point to build module
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot\src\OSDCloudCustomBuilder.psd1" -Force
Write-Host "Building OSDCloudCustomBuilder module..."

# Perform validations or build packaging
Invoke-Pester -Path ./tests -CodeCoverage ./src/OSDCloudCustomBuilder -CI
