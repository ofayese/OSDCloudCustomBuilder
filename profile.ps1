# File: profile.ps1
# Purpose: PowerShell profile to auto-import module and set aliases/functions for OSDCloudCustomBuilder dev

# Auto-import the module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'OSDCloudCustomBuilder.psm1'
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force -ErrorAction SilentlyContinue
    Write-Host "✅ OSDCloudCustomBuilder module loaded from: $modulePath" -ForegroundColor Green
} else {
    Write-Warning "⚠️ Could not find OSDCloudCustomBuilder module at: $modulePath"
}

# Set working directory
Set-Location $PSScriptRoot

# Set aliases or helper functions for testing
function Run-UnitTests {
    & "$PSScriptRoot\Run-Tests.ps1"
}

function Run-AllTests {
    & "$PSScriptRoot\Run-Tests.ps1" -IncludeSpecialized
}

function Run-CodeCoverage {
    & "$PSScriptRoot\Run-Tests.ps1" -CodeCoverage
}

Write-Host "💡 Aliases loaded: Run-UnitTests, Run-AllTests, Run-CodeCoverage" -ForegroundColor Cyan