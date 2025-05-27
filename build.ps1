# build.ps1 - Entry point to build module

# Process command-line arguments
param(
    [Parameter(Position = 0)]
    [ValidateSet('Build', 'Test', 'Analyze', 'Clean', 'Docs')]
    [string]$Task = 'Build'
)

$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot\OSDCloudCustomBuilder.psd1" -Force
Write-Host "Building OSDCloudCustomBuilder module..."

# Determine what to do based on the task
switch ($Task) {
    'Test' {
        Write-Host "Running tests..." -ForegroundColor Cyan

        # Create test helper directories if they don't exist
        $testHelpersPath = Join-Path $PSScriptRoot 'tests\TestHelpers'
        if (-not (Test-Path $testHelpersPath)) {
            New-Item -Path $testHelpersPath -ItemType Directory -Force | Out-Null
        }

        # Configure Pester
        $PesterConfig = @{
            Run          = @{
                Path        = './tests'
                ExcludePath = './tests/TestHelpers'  # Exclude the helper modules from being run as tests
            }
            CodeCoverage = @{
                Enabled      = $true
                Path         = @('./Public/*.ps1', './Private/*.ps1', './Shared/*.ps1')
                OutputPath   = './coverage.xml'
                OutputFormat = 'JaCoCo'
            }
            Output       = @{
                Verbosity = 'Detailed'
            }
            TestResult   = @{
                Enabled      = $true
                OutputPath   = './testResults.xml'
                OutputFormat = 'NUnitXml'
            }
        }

        # Try to run Pester tests first
        try {
            Invoke-Pester -Configuration $PesterConfig
        } catch {
            Write-Warning "Pester tests failed: $_"

            # Fall back to our simplified test runner
            Write-Host "Falling back to simplified test runner..." -ForegroundColor Yellow
            $simplifiedTestScript = Join-Path $PSScriptRoot 'tests\Simple-Test-Runner.ps1'
            if (Test-Path $simplifiedTestScript) {
                & $simplifiedTestScript -TestType All
            } else {
                Write-Error "Simplified test runner not found at $simplifiedTestScript"
            }
        }
    }

    'Analyze' {
        Write-Host "Analyzing code quality..." -ForegroundColor Cyan

        # Ensure PSScriptAnalyzer is installed
        if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
            Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Yellow
            Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
        }

        # Run PSScriptAnalyzer
        Invoke-ScriptAnalyzer -Path $PSScriptRoot -Recurse -Settings (Join-Path $PSScriptRoot 'PSScriptAnalyzer.settings.psd1')
    }

    'Clean' {
        Write-Host "Cleaning build artifacts..." -ForegroundColor Cyan

        # List of artifacts to remove
        $artifactPaths = @(
            './output',
            './coverage.xml',
            './testResults.xml',
            './artifacts'
        )

        # Remove each artifact
        foreach ($path in $artifactPaths) {
            $fullPath = Join-Path $PSScriptRoot $path
            if (Test-Path $fullPath) {
                Remove-Item -Path $fullPath -Recurse -Force
                Write-Host "Removed: $path" -ForegroundColor Gray
            }
        }
    }

    'Docs' {
        Write-Host "Generating documentation..." -ForegroundColor Cyan

        # Check for PlatyPS module
        if (-not (Get-Module -ListAvailable -Name PlatyPS)) {
            Write-Host "Installing PlatyPS..." -ForegroundColor Yellow
            Install-Module -Name PlatyPS -Force -Scope CurrentUser
        }

        # Generate documentation
        $docsPath = Join-Path $PSScriptRoot 'docs'
        if (-not (Test-Path $docsPath)) {
            New-Item -Path $docsPath -ItemType Directory -Force | Out-Null
        }

        # Generate documentation for each public function
        $publicFunctions = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter "*.ps1"
        foreach ($function in $publicFunctions) {
            $functionName = $function.BaseName
            $docPath = Join-Path $docsPath "$functionName.md"

            # Only generate if it doesn't exist or is older than the function file
            if (-not (Test-Path $docPath) -or
                (Get-Item $docPath).LastWriteTime -lt $function.LastWriteTime) {
                Write-Host "Generating documentation for $functionName..." -ForegroundColor Gray
                $null = New-MarkdownHelp -Command $functionName -OutputFolder $docsPath -Force
            }
        }
    }

    default {
        # 'Build'
        Write-Host "Building module..." -ForegroundColor Cyan

        # Run versioning from build.settings.ps1
        . (Join-Path $PSScriptRoot 'build.settings.ps1')

        # Copy any required files to output if needed
        $outputPath = Join-Path $PSScriptRoot 'output'
        if (-not (Test-Path $outputPath)) {
            New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
        }

        # You can add more build steps here

        # Run tests as part of the build
        & $PSCommandPath -Task Test
    }
}
