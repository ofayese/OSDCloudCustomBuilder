<#
.SYNOPSIS
    Build script for OSDCloudCustomBuilder module.
.DESCRIPTION
    This script builds, tests, and packages the OSDCloudCustomBuilder module.
    It supports various tasks including cleaning, building, testing, analyzing, and publishing.
.PARAMETER Task
    The build task(s) to execute.
.PARAMETER OutputPath
    The output directory for build artifacts.
.PARAMETER Force
    Force rebuild even if output exists.
.PARAMETER Configuration
    Build configuration (Debug or Release).
.EXAMPLE
    .\build.ps1 -Task Build
.EXAMPLE
    .\build.ps1 -Task Test,Analyze
.EXAMPLE
    .\build.ps1 -Task Publish -Configuration Release
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Clean', 'Build', 'Test', 'Analyze', 'Package', 'Publish', 'UpdateVersion')]
    [string[]]$Task = @('Clean', 'Build', 'Test', 'Analyze'),

    [Parameter()]
    [string]$OutputPath = "out",

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug'
)

# Set error handling
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Build configuration
$BuildConfig = @{
    ModuleName = 'OSDCloudCustomBuilder'
    SourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'src\OSDCloudCustomBuilder'
    OutputPath = Join-Path -Path $PSScriptRoot -ChildPath $OutputPath
    TestPath = Join-Path -Path $PSScriptRoot -ChildPath 'tests'
    Configuration = $Configuration
    Force = $Force.IsPresent
}

# Ensure required modules are available
$RequiredModules = @(
    @{ Name = 'Pester'; MinimumVersion = '5.3.0' },
    @{ Name = 'PSScriptAnalyzer'; MinimumVersion = '1.20.0' }
)

Write-Host "Checking required modules..." -ForegroundColor Cyan
foreach ($Module in $RequiredModules) {
    $InstalledModule = Get-Module -Name $Module.Name -ListAvailable |
                      Where-Object { $_.Version -ge $Module.MinimumVersion } |
                      Sort-Object -Property Version -Descending |
                      Select-Object -First 1

    if (-not $InstalledModule) {
        Write-Host "Installing $($Module.Name) v$($Module.MinimumVersion)..." -ForegroundColor Yellow
        Install-Module -Name $Module.Name -MinimumVersion $Module.MinimumVersion -Scope CurrentUser -Force -AllowClobber
    } else {
        Write-Host "Found $($Module.Name) v$($InstalledModule.Version)" -ForegroundColor Green
    }
}

# Build task functions
function Invoke-Clean {
    Write-Host "Cleaning output directory..." -ForegroundColor Cyan
    if (Test-Path -Path $BuildConfig.OutputPath) {
        Remove-Item -Path $BuildConfig.OutputPath -Recurse -Force
    }
    New-Item -Path $BuildConfig.OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "Output directory cleaned: $($BuildConfig.OutputPath)" -ForegroundColor Green
}

function Invoke-UpdateVersion {
    Write-Host "Updating module version..." -ForegroundColor Cyan

    # Read current version from manifest
    $manifestPath = Join-Path -Path $BuildConfig.SourcePath -ChildPath "$($BuildConfig.ModuleName).psd1"
    $manifest = Import-PowerShellDataFile -Path $manifestPath
    $currentVersion = [Version]$manifest.ModuleVersion

    # Increment build number
    $newVersion = New-Object Version $currentVersion.Major, $currentVersion.Minor, ($currentVersion.Build + 1)

    Write-Host "Updating version from $currentVersion to $newVersion" -ForegroundColor Yellow

    # Update manifest
    $manifestContent = Get-Content -Path $manifestPath -Raw
    $manifestContent = $manifestContent -replace "ModuleVersion\s*=\s*['`"]$currentVersion['`"]", "ModuleVersion = '$newVersion'"
    $manifestContent | Set-Content -Path $manifestPath -Force

    # Update module file if it contains version
    $moduleFilePath = Join-Path -Path $BuildConfig.SourcePath -ChildPath "$($BuildConfig.ModuleName).psm1"
    if (Test-Path -Path $moduleFilePath) {
        $moduleContent = Get-Content -Path $moduleFilePath -Raw
        if ($moduleContent -match 'script:ModuleVersion\s*=\s*[''"][\d\.]+[''"]') {
            $moduleContent = $moduleContent -replace 'script:ModuleVersion\s*=\s*[''"][\d\.]+[''"]', "script:ModuleVersion = '$newVersion'"
            $moduleContent | Set-Content -Path $moduleFilePath -Force
        }
    }

    Write-Host "Version updated to $newVersion" -ForegroundColor Green
}

function Invoke-CopyFiles {
    Write-Host "Copying module files..." -ForegroundColor Cyan

    $destinationPath = Join-Path -Path $BuildConfig.OutputPath -ChildPath $BuildConfig.ModuleName
    New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null

    # Copy all module files
    $filesToCopy = @(
        '*.psd1',
        '*.psm1',
        'Public\*.ps1',
        'Private\*.ps1',
        'Shared\*.ps1',
        'Shared\*.psm1',
        'Classes\*.ps1'
    )

    foreach ($pattern in $filesToCopy) {
        $sourcePath = Join-Path -Path $BuildConfig.SourcePath -ChildPath $pattern
        $files = Get-ChildItem -Path $sourcePath -ErrorAction SilentlyContinue

        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($BuildConfig.SourcePath.Length + 1)
            $destFile = Join-Path -Path $destinationPath -ChildPath $relativePath
            $destDir = Split-Path -Path $destFile -Parent

            if (-not (Test-Path -Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }

            Copy-Item -Path $file.FullName -Destination $destFile -Force
            Write-Verbose "Copied: $relativePath"
        }
    }

    Write-Host "Module files copied to: $destinationPath" -ForegroundColor Green
}

function Invoke-Analyze {
    Write-Host "Running static code analysis..." -ForegroundColor Cyan

    # Import PSScriptAnalyzer
    Import-Module -Name PSScriptAnalyzer -Force

    # Run analysis
    $settingsPath = Join-Path -Path $PSScriptRoot -ChildPath 'PSScriptAnalyzer.settings.psd1'
    if (Test-Path -Path $settingsPath) {
        $analysisResults = Invoke-ScriptAnalyzer -Path $BuildConfig.SourcePath -Recurse -Settings $settingsPath
    } else {
        $analysisResults = Invoke-ScriptAnalyzer -Path $BuildConfig.SourcePath -Recurse
    }

    if ($analysisResults) {
        Write-Host "Analysis Results:" -ForegroundColor Yellow
        $analysisResults | Format-Table -AutoSize

        $errorCount = ($analysisResults | Where-Object { $_.Severity -eq 'Error' }).Count
        $warningCount = ($analysisResults | Where-Object { $_.Severity -eq 'Warning' }).Count
        $infoCount = ($analysisResults | Where-Object { $_.Severity -eq 'Information' }).Count

        Write-Host "Analysis Summary: $errorCount errors, $warningCount warnings, $infoCount informational" -ForegroundColor Cyan

        if ($errorCount -gt 0) {
            throw "PSScriptAnalyzer found $errorCount errors. Build failed."
        }

        if ($warningCount -gt 0 -and $BuildConfig.Configuration -eq 'Release') {
            Write-Warning "PSScriptAnalyzer found $warningCount warnings in Release mode."
        }
    } else {
        Write-Host "No analysis issues found!" -ForegroundColor Green
    }
}

function Invoke-Test {
    Write-Host "Running tests..." -ForegroundColor Cyan

    # Import Pester
    Import-Module -Name Pester -Force

    # Configure Pester
    $config = New-PesterConfiguration
    $config.Run.Path = $BuildConfig.TestPath
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Detailed'
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = $BuildConfig.SourcePath
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
    $config.CodeCoverage.OutputPath = Join-Path -Path $BuildConfig.OutputPath -ChildPath 'coverage.xml'

    # Run tests
    $results = Invoke-Pester -Configuration $config

    # Check results
    if ($results.FailedCount -gt 0) {
        throw "Pester tests failed. $($results.FailedCount) test(s) failed."
    }

    Write-Host "All tests passed! Coverage: $([math]::Round($results.CodeCoverage.CoveragePercent, 2))%" -ForegroundColor Green
}

function Invoke-Package {
    Write-Host "Creating package..." -ForegroundColor Cyan

    $packagePath = Join-Path -Path $BuildConfig.OutputPath -ChildPath "$($BuildConfig.ModuleName).zip"
    $modulePath = Join-Path -Path $BuildConfig.OutputPath -ChildPath $BuildConfig.ModuleName

    if (Test-Path -Path $packagePath) {
        Remove-Item -Path $packagePath -Force
    }

    # Create ZIP package
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        Compress-Archive -Path "$modulePath\*" -DestinationPath $packagePath -Force
    } else {
        # Fallback for older PowerShell versions
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($modulePath, $packagePath)
    }

    Write-Host "Package created: $packagePath" -ForegroundColor Green
}

function Invoke-Publish {
    Write-Host "Publishing module..." -ForegroundColor Cyan

    # Check if API key is available
    if (-not $env:PSGALLERY_API_KEY) {
        Write-Warning "PowerShell Gallery API key not found. Set the PSGALLERY_API_KEY environment variable to publish."
        return
    }

    # Publish to PowerShell Gallery
    $modulePath = Join-Path -Path $BuildConfig.OutputPath -ChildPath $BuildConfig.ModuleName

    try {
        Publish-Module -Path $modulePath -NugetApiKey $env:PSGALLERY_API_KEY -Verbose -Force
        Write-Host "Module published successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to publish module: $_"
        throw
    }
}

# Execute the specified tasks
try {
    Write-Host "Starting build with tasks: $($Task -join ', ')" -ForegroundColor Cyan
    Write-Host "Configuration: $($BuildConfig.Configuration)" -ForegroundColor Cyan
    Write-Host "Output Path: $($BuildConfig.OutputPath)" -ForegroundColor Cyan

    foreach ($TaskName in $Task) {
        switch ($TaskName) {
            'Clean' { Invoke-Clean }
            'UpdateVersion' { Invoke-UpdateVersion }
            'Build' {
                Invoke-Clean
                Invoke-CopyFiles
            }
            'Test' { Invoke-Test }
            'Analyze' { Invoke-Analyze }
            'Package' { Invoke-Package }
            'Publish' { Invoke-Publish }
            default { Write-Warning "Unknown task: $TaskName" }
        }
    }

    Write-Host "Build completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Build failed: $_" -ForegroundColor Red
    exit 1
}
