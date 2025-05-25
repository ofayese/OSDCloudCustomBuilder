<#
.SYNOPSIS
    Complete build automation for OSDCloudCustomBuilder.

.DESCRIPTION
    This script handles version bumping, running tests, analyzing scripts, and packaging the module for publish.
#>

$ErrorActionPreference = 'Stop'

# Paths
$ModuleName = 'OSDCloudCustomBuilder'
$ModulePath = Join-Path $PSScriptRoot $ModuleName
$ManifestPath = Join-Path $ModulePath "$ModuleName.psd1"
$BuildSettings = Join-Path $ModulePath 'build.settings.ps1'

# Step 1: Update version
Write-Host "🔄 Bumping version..."
. $BuildSettings

# Step 2: Run PSScriptAnalyzer
Write-Host "🔍 Analyzing scripts with PSScriptAnalyzer..."
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
Invoke-ScriptAnalyzer -Path $ModulePath -Recurse -Settings (Join-Path $ModulePath 'PSScriptAnalyzer.settings.psd1')

# Step 3: Run Pester tests
Write-Host "🧪 Running Pester tests..."
Invoke-Pester -Path (Join-Path $ModulePath 'tests') -Output Detailed

# Step 4: Package module
$OutputFolder = Join-Path $PSScriptRoot 'artifacts'
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$ModuleZip = Join-Path $OutputFolder "$ModuleName-$((Test-ModuleManifest -Path $ManifestPath).Version).zip"
Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
[System.IO.Compression.ZipFile]::CreateFromDirectory($ModulePath, $ModuleZip, 'Optimal', $false)

Write-Host "✅ Build complete. Package created at $ModuleZip"
