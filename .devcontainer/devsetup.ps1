#Requires -Version 7.0

<#
.SYNOPSIS
    Enhanced PowerShell module installation for OSDCloudCustomBuilder development.

.DESCRIPTION
    This script installs all required PowerShell modules for developing and testing
    the OSDCloudCustomBuilder module in a development container environment.

    It includes modules for testing, analysis, build automation, and OS deployment.

.PARAMETER Force
    Force reinstallation of modules even if they're already installed.

.PARAMETER Scope
    Installation scope for modules. Default is 'AllUsers' for containers.

.EXAMPLE
    .\devsetup.ps1
    Install all required modules with default settings.

.EXAMPLE
    .\devsetup.ps1 -Force
    Force reinstall all modules.
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string]$Scope = 'AllUsers'
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "🚀 OSDCloudCustomBuilder Development Environment Setup" -ForegroundColor Green
Write-Host "=" * 60

# Set PowerShell Gallery as trusted
Write-Host "🔧 Configuring PowerShell Gallery..." -ForegroundColor Cyan
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Define module requirements with specific versions for consistency
$RequiredModules = @(
    @{
        Name        = "Pester";
        Version     = "5.5.0";
        Description = "PowerShell testing framework for unit testing and mocking";
        Category    = "Testing"
    },
    @{
        Name        = "PSScriptAnalyzer";
        Version     = "1.21.0";
        Description = "Static code analysis tool for PowerShell best practices";
        Category    = "Code Quality"
    },
    @{
        Name        = "PSReadLine";
        Version     = "2.3.4";
        Description = "Enhanced command-line editing experience";
        Category    = "Developer Experience"
    },
    @{
        Name        = "PSFramework";
        Version     = "1.7.270";
        Description = "Logging, configuration, and utility framework";
        Category    = "Framework"
    },
    @{
        Name        = "PSDepend";
        Version     = "0.3.8";
        Description = "Dependency management for PowerShell projects";
        Category    = "Build Tools"
    },
    @{
        Name        = "InvokeBuild";
        Version     = "5.10.4";
        Description = "Build and task automation tool";
        Category    = "Build Tools"
    },
    @{
        Name        = "ModuleBuilder";
        Version     = "2.0.0";
        Description = "Module building and packaging utilities";
        Category    = "Build Tools"
    },
    @{
        Name        = "PSModuleDevelopment";
        Version     = "2.2.9.94";
        Description = "Development tools and templates for PowerShell modules";
        Category    = "Development"
    },
    @{
        Name        = "Plaster";
        Version     = "1.1.3";
        Description = "Template-based file and project generator";
        Category    = "Development"
    },
    @{
        Name        = "PowerShellGet";
        Version     = "2.2.5";
        Description = "Package management for PowerShell modules";
        Category    = "Package Management"
    },
    @{
        Name        = "PackageManagement";
        Version     = "1.4.8.1";
        Description = "Package management infrastructure";
        Category    = "Package Management"
    },
    @{
        Name        = "PSRule";
        Version     = "2.9.0";
        Description = "Rule-based validation framework";
        Category    = "Code Quality"
    },
    @{
        Name        = "PSRule.Rules.Azure";
        Version     = "1.30.1";
        Description = "Azure-specific validation rules";
        Category    = "Code Quality"
    },
    @{
        Name        = "OSD";
        Version     = "23.5.26.1";
        Description = "OS deployment automation and customization";
        Category    = "OS Deployment"
    },
    @{
        Name        = "PowerShellProTools";
        Version     = "5.8.6";
        Description = "Professional PowerShell development tools";
        Category    = "Development"
    }
)

# Group modules by category for better organization
$ModulesByCategory = $RequiredModules | Group-Object Category

# Install modules by category
foreach ($category in $ModulesByCategory) {
    Write-Host "`n📦 Installing $($category.Name) modules..." -ForegroundColor Yellow
    Write-Host "-" * 40

    foreach ($moduleInfo in $category.Group) {
        $moduleName = $moduleInfo.Name
        $requiredVersion = $moduleInfo.Version
        $description = $moduleInfo.Description

        Write-Host "`n🔧 $moduleName v$requiredVersion" -ForegroundColor White
        Write-Host "   $description" -ForegroundColor Gray

        try {
            # Check if module is already installed with correct version
            $installedModule = Get-InstalledModule -Name $moduleName -RequiredVersion $requiredVersion -ErrorAction SilentlyContinue

            if ($installedModule -and -not $Force) {
                Write-Host "   ✅ Already installed" -ForegroundColor Green
                continue
            }

            # Install or update the module
            $installParams = @{
                Name            = $moduleName
                RequiredVersion = $requiredVersion
                Scope           = $Scope
                Force           = $true
                AllowClobber    = $true
                ErrorAction     = 'Stop'
            }

            if ($Force) {
                $installParams.Add('Reinstall', $true)
            }

            Install-Module @installParams
            Write-Host "   ✅ Successfully installed" -ForegroundColor Green

        } catch {
            Write-Warning "   ❌ Failed to install $moduleName`: $_"

            # Try alternative installation method
            try {
                Write-Host "   🔄 Attempting alternative installation..." -ForegroundColor Yellow
                Install-Module -Name $moduleName -Scope $Scope -Force -AllowClobber -SkipPublisherCheck
                Write-Host "   ✅ Alternative installation successful" -ForegroundColor Green
            } catch {
                Write-Error "   ❌ All installation methods failed for $moduleName`: $_"
            }
        }
    }
}

# Verify installations and show summary
Write-Host "`n📊 Installation Summary" -ForegroundColor Green
Write-Host "=" * 60

$installedModules = Get-InstalledModule | Where-Object { $_.Name -in $RequiredModules.Name }
$successfulInstalls = @()
$failedInstalls = @()

foreach ($module in $RequiredModules) {
    $installed = $installedModules | Where-Object { $_.Name -eq $module.Name }
    if ($installed) {
        $successfulInstalls += [PSCustomObject]@{
            Name             = $module.Name
            InstalledVersion = $installed.Version
            RequiredVersion  = $module.Version
            Status           = if ($installed.Version -eq $module.Version) { "✅ Correct" } else { "⚠️ Different" }
        }
    } else {
        $failedInstalls += $module.Name
    }
}

if ($successfulInstalls) {
    Write-Host "`n✅ Successfully installed modules:" -ForegroundColor Green
    $successfulInstalls | Format-Table Name, InstalledVersion, RequiredVersion, Status -AutoSize
}

if ($failedInstalls) {
    Write-Host "`n❌ Failed to install modules:" -ForegroundColor Red
    $failedInstalls | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
}

# Configure PowerShell for optimal development experience
Write-Host "`n⚙️ Configuring PowerShell development environment..." -ForegroundColor Cyan

# Set execution policy for development
if ((Get-ExecutionPolicy) -eq 'Restricted') {
    Write-Host "   Setting execution policy to RemoteSigned..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

# Import key modules for immediate use
$ImportModules = @('Pester', 'PSScriptAnalyzer', 'InvokeBuild')
foreach ($moduleName in $ImportModules) {
    try {
        Import-Module $moduleName -Force
        Write-Host "   ✅ Imported $moduleName" -ForegroundColor Green
    } catch {
        Write-Warning "   ⚠️ Could not import $moduleName`: $_"
    }
}

# Create module development shortcuts
Write-Host "`n🔗 Creating development shortcuts..." -ForegroundColor Cyan

# Create global functions for common tasks
$functionsScript = @'
# OSDCloudCustomBuilder Development Functions

function Test-ModuleStructure {
    <#
    .SYNOPSIS
        Validates the module structure and manifest.
    #>
    [CmdletBinding()]
    param()

    Write-Host "🔍 Validating module structure..." -ForegroundColor Cyan

    # Check for required files
    $requiredFiles = @('OSDCloudCustomBuilder.psd1', 'OSDCloudCustomBuilder.psm1')
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Host "   ✅ $file exists" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $file missing" -ForegroundColor Red
        }
    }

    # Validate manifest
    try {
        $manifest = Test-ModuleManifest -Path './OSDCloudCustomBuilder.psd1' -ErrorAction Stop
        Write-Host "   ✅ Module manifest is valid" -ForegroundColor Green
        Write-Host "   📄 Version: $($manifest.Version)" -ForegroundColor Cyan
        Write-Host "   📄 Functions: $($manifest.ExportedFunctions.Count)" -ForegroundColor Cyan
    } catch {
        Write-Host "   ❌ Module manifest validation failed: $_" -ForegroundColor Red
    }
}

function Start-DevTest {
    <#
    .SYNOPSIS
        Runs a comprehensive development test suite.
    #>
    [CmdletBinding()]
    param(
        [switch]$Coverage,
        [switch]$SkipAnalysis
    )

    Write-Host "🧪 Starting development test suite..." -ForegroundColor Yellow

    # Run PSScriptAnalyzer
    if (-not $SkipAnalysis) {
        Write-Host "`n🔍 Running PSScriptAnalyzer..."
        $analysisResults = Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSScriptAnalyzer.settings.psd1
        if ($analysisResults) {
            $analysisResults | Format-Table
            Write-Host "   ⚠️ Found $($analysisResults.Count) analysis issues" -ForegroundColor Yellow
        } else {
            Write-Host "   ✅ No analysis issues found" -ForegroundColor Green
        }
    }

    # Run Pester tests
    Write-Host "`n🧪 Running Pester tests..."
    $pesterParams = @{
        Path = './tests'
        OutputFormat = 'NUnitXml'
        OutputFile = 'TestResults.xml'
        PassThru = $true
    }

    if ($Coverage) {
        $pesterParams.CodeCoverage = @('./Public/*.ps1', './Private/*.ps1')
    }

    $testResults = Invoke-Pester @pesterParams

    if ($testResults.FailedCount -eq 0) {
        Write-Host "   ✅ All tests passed!" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $($testResults.FailedCount) tests failed" -ForegroundColor Red
    }

    if ($Coverage -and $testResults.CodeCoverage) {
        $coveragePercent = [math]::Round(($testResults.CodeCoverage.NumberOfCommandsExecuted / $testResults.CodeCoverage.NumberOfCommandsAnalyzed) * 100, 2)
        Write-Host "   📊 Code coverage: $coveragePercent%" -ForegroundColor Cyan
    }
}

function Show-DevEnvironment {
    <#
    .SYNOPSIS
        Shows the current development environment status.
    #>
    Write-Host "🚀 OSDCloudCustomBuilder Development Environment" -ForegroundColor Green
    Write-Host "=" * 50

    # PowerShell version
    Write-Host "📋 PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan

    # .NET version
    try {
        $dotnetVersion = & dotnet --version 2>$null
        Write-Host "📋 .NET SDK: $dotnetVersion" -ForegroundColor Cyan
    } catch {
        Write-Host "📋 .NET SDK: Not available" -ForegroundColor Yellow
    }

    # Key modules
    Write-Host "`n📦 Key Modules:" -ForegroundColor Cyan
    $keyModules = @('Pester', 'PSScriptAnalyzer', 'InvokeBuild', 'OSD')
    foreach ($module in $keyModules) {
        $mod = Get-Module -Name $module -ListAvailable | Select-Object -First 1
        if ($mod) {
            Write-Host "   ✅ $($mod.Name) v$($mod.Version)" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $module not found" -ForegroundColor Red
        }
    }

    # Project status
    Write-Host "`n📁 Project Files:" -ForegroundColor Cyan
    $projectFiles = @('OSDCloudCustomBuilder.psd1', 'OSDCloudCustomBuilder.psm1', 'OSDCloudCustomBuilder.csproj', 'build.ps1')
    foreach ($file in $projectFiles) {
        if (Test-Path $file) {
            Write-Host "   ✅ $file" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $file" -ForegroundColor Yellow
        }
    }

    Write-Host "`n💡 Available commands:"
    Write-Host "   Test-ModuleStructure  - Validate module structure"
    Write-Host "   Start-DevTest         - Run comprehensive tests"
    Write-Host "   Show-DevEnvironment   - Show this information"
}

# Make functions available globally
Export-ModuleMember -Function Test-ModuleStructure, Start-DevTest, Show-DevEnvironment
'@

# Save functions to a temporary module
$tempModulePath = Join-Path $env:TEMP "OSDCloudDevFunctions.psm1"
Set-Content -Path $tempModulePath -Value $functionsScript
Import-Module $tempModulePath -Force -Global

Write-Host "`n🎉 Development environment setup complete!" -ForegroundColor Green
Write-Host "=" * 60

# Show final summary
Show-DevEnvironment

Write-Host "`n💡 Quick start commands:" -ForegroundColor Yellow
Write-Host "   Show-DevEnvironment   - View environment status"
Write-Host "   Test-ModuleStructure  - Validate module structure"
Write-Host "   Start-DevTest         - Run all tests"
Write-Host "   Start-DevTest -Coverage - Run tests with coverage"

Write-Host "`nHappy developing! 🚀" -ForegroundColor Green
