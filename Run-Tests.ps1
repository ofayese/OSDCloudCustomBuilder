param(
    [switch]$IncludeSpecialized,
    [string[]]$Tags = @(),
    [switch]$CodeCoverage,
    [string]$OutputFile = "",
    [ValidateSet('NUnitXml', 'JUnitXml')]
    [string]$Format = 'NUnitXml'
)
Import-Module Pester -MinimumVersion 5.0 -Force

$config = [PesterConfiguration]::Default
$config.Run.Path = @(Join-Path $PSScriptRoot 'Tests\Unit')

if ($IncludeSpecialized) {
    $extraPaths = 'Security', 'Performance', 'ErrorHandling', 'Integration' | 
        ForEach-Object { Join-Path $PSScriptRoot "Tests\$_" } | 
        Where-Object { Test-Path $_ }
    $config.Run.Path += $extraPaths
}

if ($Tags) { $config.Filter.Tag = $Tags }
if ($OutputFile) {
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = $OutputFile
    $config.TestResult.OutputFormat = $Format
}

if ($CodeCoverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.OutputPath = Join-Path $PSScriptRoot 'coverage.xml'
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
    $config.CodeCoverage.Path = @(
        "$PSScriptRoot\OSDCloudCustomBuilder.psm1",
        "$PSScriptRoot\Public\*.ps1",
        "$PSScriptRoot\Private\*.ps1"
    )
}

Write-Host "`nRunning tests..." -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $config -PassThru
Write-Host "`nResults: Passed=$($results.PassedCount), Failed=$($results.FailedCount)" -ForegroundColor Green
return $results