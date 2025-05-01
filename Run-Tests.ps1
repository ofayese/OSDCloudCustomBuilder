<<<<<<< HEAD
# Script for running OSDCloudCustomBuilder tests
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    Runs tests for the OSDCloudCustomBuilder module.
.DESCRIPTION
    Executes Pester tests for the OSDCloudCustomBuilder module, with options for standard or specialized tests.
.PARAMETER IncludeSpecialized
    Run specialized tests in addition to standard tests.
.PARAMETER Tags
    Only run tests with specific tags.
.PARAMETER CodeCoverage
    Enable code coverage reporting.
.PARAMETER OutputFile
    Path to save test results.
.PARAMETER Format
    Format of test results (NUnitXml or JUnitXml).
.PARAMETER TestPath
    Specific test path to run. Default is to run all tests.
.PARAMETER ShowFailedTestOutput
    Show the full output from failed tests. Useful for debugging.
#>

param(
        [switch]$IncludeSpecialized,
        [string[]]$Tags = @(),
        [switch]$CodeCoverage,
        [string]$OutputFile,
        [ValidateSet('NUnitXml', 'JUnitXml')]
        [string]$Format = 'NUnitXml',
        [string]$TestPath,
        [switch]$ShowFailedTestOutput
    )

# Ensure we're using Pester 5.x
$pesterModule = Get-Module -Name Pester -ListAvailable |
                Sort-Object -Property Version -Descending |
                Select-Object -First 1

if (-not $pesterModule -or $pesterModule.Version.Major -lt 5) {
    Write-Error "Pester 5.0 or higher is required. Please install using: Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck"
    return
}

# Import Pester module
Import-Module -Name Pester -MinimumVersion 5.0 -Force

# Define the configuration
$config = [PesterConfiguration]::Default
$config.Run.PassThru = $true
$config.Output.Verbosity = "Detailed"
$config.TestResult.Enabled = -not [string]::IsNullOrWhiteSpace($OutputFile)
$config.Debug.ShowFullErrors = $ShowFailedTestOutput

# Use provided test path or default to all tests
if ($TestPath) {
    $config.Run.Path = $TestPath
} else {
    $config.Run.Path = @(
        (Join-Path -Path $PSScriptRoot -ChildPath "Tests\Unit"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Tests\OSDCloudCustomBuilder.Tests.ps1")
    )
}

if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
    $config.TestResult.OutputPath = $OutputFile
    $config.TestResult.OutputFormat = $Format
}

# Add specialized test paths if requested
if ($IncludeSpecialized) {
    $specializedPaths = @(
        (Join-Path -Path $PSScriptRoot -ChildPath "Tests\Security"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Tests\Performance"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Tests\ErrorHandling"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Tests\Integration")
    )

    # Filter to only include paths that exist
    $validSpecializedPaths = $specializedPaths | Where-Object { Test-Path -Path $_ }

    if ($validSpecializedPaths.Count -gt 0) {
        $config.Run.Path = @($config.Run.Path) + $validSpecializedPaths
    }
}

# Configure tags if specified
if ($Tags.Count -gt 0) {
    $config.Filter.Tag = $Tags
}

# Configure code coverage if requested
if ($CodeCoverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = @(
        (Join-Path -Path $PSScriptRoot -ChildPath "OSDCloudCustomBuilder.psm1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Public\*.ps1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Private\*.ps1")
    )
    $config.CodeCoverage.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "coverage.xml"
    $config.CodeCoverage.OutputFormat = "JaCoCo"
}

# Display test configuration
Write-Host "Running tests with the following configuration:" -ForegroundColor Cyan
Write-Host "  - Test Paths: $($config.Run.Path -join ', ')" -ForegroundColor Cyan
if ($Tags.Count -gt 0) {
    Write-Host "  - Tags: $($Tags -join ', ')" -ForegroundColor Cyan
}
Write-Host "  - Code Coverage: $($CodeCoverage)" -ForegroundColor Cyan
if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
    Write-Host "  - Output File: $OutputFile ($Format)" -ForegroundColor Cyan
}

# Run the tests
Write-Host "`nStarting Pester tests..." -ForegroundColor Green
$testResults = Invoke-Pester -Configuration $config

# Display summary
Write-Host "`nTest Results Summary:" -ForegroundColor Cyan
Write-Host "  - Total Tests: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  - Passed: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  - Failed: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  - Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  - NotRun: $($testResults.NotRunCount)" -ForegroundColor Gray

# Show test run details
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $testResults.Failed | ForEach-Object {
        Write-Host "  - $($_.Name) in $($_.Path.Replace($PSScriptRoot, '.'))" -ForegroundColor Red
        if ($ShowFailedTestOutput) {
            Write-Host "    Error: $($_.ErrorRecord.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

    return $testResults
return $testResults
=======
# Script for running OSDCloudCustomBuilder tests
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    Runs tests for the OSDCloudCustomBuilder module.
.DESCRIPTION
    Executes Pester tests for the OSDCloudCustomBuilder module, with options for standard or specialized tests.
.PARAMETER IncludeSpecialized
    Run specialized tests in addition to standard tests.
.PARAMETER Tags
    Only run tests with specific tags.
.PARAMETER CodeCoverage
    Enable code coverage reporting.
.PARAMETER OutputFile
    Path to save test results.
.PARAMETER Format
    Format of test results (NUnitXml or JUnitXml).
#>
[CmdletBinding()]
param(
    [switch]$IncludeSpecialized,
    [string[]]$Tags = @(),
    [switch]$CodeCoverage,
    [string]$OutputFile,
    [ValidateSet('NUnitXml', 'JUnitXml')]
    [string]$Format = 'NUnitXml'
)

# Ensure we're using Pester 5.x
$pesterModule = Get-Module -Name Pester -ListAvailable | 
                Sort-Object -Property Version -Descending | 
                Select-Object -First 1

if (-not $pesterModule -or $pesterModule.Version.Major -lt 5) {
    Write-Error "Pester 5.0 or higher is required. Please install using: Install-Module -Name Pester -MinimumVersion 5.0 -Force"
    return
}

# Import Pester module
Import-Module -Name Pester -MinimumVersion 5.0 -Force

# Define the configuration
$config = [PesterConfiguration]::Default
$config.Run.Path = Join-Path -Path $PSScriptRoot -ChildPath "Tests\Unit"
$config.Output.Verbosity = "Detailed"
$config.TestResult.Enabled = $OutputFile.Length -gt 0

if ($OutputFile) {
    $config.TestResult.OutputPath = $OutputFile
    $config.TestResult.OutputFormat = $Format
}

# Add specialized test paths if requested
if ($IncludeSpecialized) {
    $specializedPaths = @(
        (Join-Path -Path $PSScriptRoot -ChildPath "Tests\Security"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Tests\Performance"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Tests\ErrorHandling"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Tests\Integration")
    )
    
    # Filter to only include paths that exist
    $validSpecializedPaths = $specializedPaths | Where-Object { Test-Path -Path $_ }
    
    if ($validSpecializedPaths.Count -gt 0) {
        $config.Run.Path = @($config.Run.Path) + $validSpecializedPaths
    }
}

# Configure tags if specified
if ($Tags.Count -gt 0) {
    $config.Filter.Tag = $Tags
}

# Configure code coverage if requested
if ($CodeCoverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = @(
        (Join-Path -Path $PSScriptRoot -ChildPath "OSDCloudCustomBuilder.psm1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Public\*.ps1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Private\*.ps1")
    )
    $config.CodeCoverage.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "coverage.xml"
    $config.CodeCoverage.OutputFormat = "JaCoCo"
}

# Display test configuration
Write-Host "Running tests with the following configuration:" -ForegroundColor Cyan
Write-Host "  - Test Paths: $($config.Run.Path -join ', ')" -ForegroundColor Cyan
if ($Tags.Count -gt 0) {
    Write-Host "  - Tags: $($Tags -join ', ')" -ForegroundColor Cyan
}
Write-Host "  - Code Coverage: $($CodeCoverage)" -ForegroundColor Cyan
if ($OutputFile) {
    Write-Host "  - Output File: $OutputFile ($Format)" -ForegroundColor Cyan
}

# Run the tests
Write-Host "`nStarting Pester tests..." -ForegroundColor Green
$testResults = Invoke-Pester -Configuration $config -PassThru

# Display summary
Write-Host "`nTest Results Summary:" -ForegroundColor Cyan
Write-Host "  - Total Tests: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  - Passed: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  - Failed: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  - Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  - NotRun: $($testResults.NotRunCount)" -ForegroundColor Gray

# Return test results in case this script is called from another script
return $testResults
>>>>>>> 8576c024e7d41f92195c4737d0c7f818a8ab6111
