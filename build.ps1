# build.ps1 - Entry point to build module
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot\OSDCloudCustomBuilder.psd1" -Force
Write-Host "Building OSDCloudCustomBuilder module..."

# Perform validations or build packaging
$PesterConfig = @{
    Run          = @{
        Path = './tests'
    }
    CodeCoverage = @{
        Enabled = $true
        Path    = @('./Public/*.ps1', './Private/*.ps1', './Shared/*.ps1')
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
}

Invoke-Pester -Configuration $PesterConfig
