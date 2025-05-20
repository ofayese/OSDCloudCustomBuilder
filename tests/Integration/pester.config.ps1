param(
    [string]$TestPath = './Tests',
    [string]$OutputPath = './TestResults.xml',
    [string]$CoverageOutputPath = './CodeCoverage.xml',
    [ValidateSet('Minimal', 'Normal', 'Detailed', 'Diagnostic')]
    [string]$Verbosity = 'Detailed'
)
Set-StrictMode -Version Latest

$config = New-PesterConfiguration
$config.Run.Path = $TestPath
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = $OutputPath
$config.Output.Verbosity = $Verbosity
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.OutputPath = $CoverageOutputPath
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.Debug.ShowFullErrors = $true
$config.Debug.WriteDebugMessages = $true

$config.CodeCoverage.Path = @(Resolve-Path './Private','./Public' -ErrorAction SilentlyContinue | ForEach-Object { $_.Path })

return $config