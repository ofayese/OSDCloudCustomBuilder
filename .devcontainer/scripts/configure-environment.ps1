# Configure development environment
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Status {
    param (
        [string]$Message
    )
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" -ForegroundColor Cyan
}

try {
    Write-Status "Starting environment configuration"

    # Create PowerShell profile directory if it doesn't exist
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path -Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        Write-Status "Created PowerShell profile directory: $profileDir"
    }

    # Create PowerShell profile
    Write-Status "Creating PowerShell profile"
    $profileContent = @'
# PowerShell Profile for OSDCloud Development
Write-Host "Loading OSDCloud development profile..." -ForegroundColor Cyan

# Import common modules
Import-Module PSScriptAnalyzer -ErrorAction SilentlyContinue
Import-Module Pester -ErrorAction SilentlyContinue
Import-Module InvokeBuild -ErrorAction SilentlyContinue
Import-Module OSD -ErrorAction SilentlyContinue

# Set aliases
Set-Alias -Name build -Value Invoke-Build
Set-Alias -Name test -Value Invoke-Pester
Set-Alias -Name analyze -Value Invoke-ScriptAnalyzer

# Custom functions
function Start-ModuleBuild {
    param (
        [string]$Task = 'Build'
    )
    Invoke-Build -Task $Task
}

function Start-ModuleTest {
    param (
        [string]$Path = './Tests'
    )
    Invoke-Pester -Path $Path
}

function Start-CodeAnalysis {
    param (
        [string]$Path = '.',
        [switch]$Recurse
    )
    Invoke-ScriptAnalyzer -Path $Path -Recurse:$Recurse
}

function New-ModuleProject {
    param (
        [Parameter(Mandatory)]
        [string]$ModuleName,
        [string]$Description = "PowerShell module for $ModuleName",
        [string]$Author = $env:USERNAME,
        [string]$Path = "."
    )
    
    $templateParams = @{
        TemplatePath = "Plaster\NewModule"
        DestinationPath = Join-Path -Path $Path -ChildPath $ModuleName
        ModuleName = $ModuleName
        Description = $Description
        Author = $Author
    }
    
    if (Get-Module -Name Plaster -ListAvailable) {
        Invoke-Plaster @templateParams -NoLogo
    }
    else {
        Write-Warning "Plaster module not found. Please install it with: Install-Module -Name Plaster -Force"
    }
}

function New-OSDCloudISO {
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$OutputPath = "C:\OSDCloud\ISO"
    )
    
    if (Get-Module -Name OSD -ListAvailable) {
        New-OSDCloudISO -Name $Name -OutputPath $OutputPath
    }
    else {
        Write-Warning "OSD module not found. Please install it with: Install-Module -Name OSD -Force"
    }
}

# Set location to workspace
Set-Location C:\workspace

Write-Host "OSDCloud development environment ready!" -ForegroundColor Green
'@

    Set-Content -Path $PROFILE -Value $profileContent
    Write-Status "Created PowerShell profile at: $PROFILE"

    # Create workspace directory structure
    $workspaceDir = "C:\workspace"
    if (-not (Test-Path -Path $workspaceDir)) {
        New-Item -Path $workspaceDir -ItemType Directory -Force | Out-Null
        Write-Status "Created workspace directory: $workspaceDir"
    }

    # Create templates directory
    $templatesDir = Join-Path -Path $workspaceDir -ChildPath "Templates"
    if (-not (Test-Path -Path $templatesDir)) {
        New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null
        Write-Status "Created templates directory: $templatesDir"
    }

    # Create build script template
    $buildScriptPath = Join-Path -Path $templatesDir -ChildPath "build.ps1"
    $buildScriptContent = @'
<#
.SYNOPSIS
    Build script for PowerShell module
.DESCRIPTION
    This build script uses InvokeBuild to automate the build and packaging process
#>
param(
    [string]$Task = 'Default'
)

# Install dependencies if not already installed
if (-not (Get-Module -ListAvailable -Name InvokeBuild)) {
    Install-Module InvokeBuild -Force
}

# Import build module
Import-Module InvokeBuild

# Define default task
task Default -depends Clean, Analyze, Test, Build

# Clean output directory
task Clean {
    if (Test-Path -Path .\Output) {
        Remove-Item -Path .\Output -Recurse -Force
    }
    New-Item -Path .\Output -ItemType Directory -Force | Out-Null
}

# Run PSScriptAnalyzer
task Analyze {
    $analyzerResults = Invoke-ScriptAnalyzer -Path .\Source -Recurse -Verbose:$false
    if ($analyzerResults) {
        $analyzerResults | Format-Table
        throw "One or more PSScriptAnalyzer errors/warnings were found."
    }
}

# Run Pester tests
task Test {
    $testResults = Invoke-Pester -Path .\Tests -PassThru
    if ($testResults.FailedCount -gt 0) {
        throw "$($testResults.FailedCount) tests failed."
    }
}

# Build module
task Build {
    # Copy module files to output directory
    Copy-Item -Path .\Source\* -Destination .\Output -Recurse
    
    # Generate documentation
    if (Get-Module -ListAvailable -Name platyPS) {
        New-ExternalHelp -Path .\Docs -OutputPath .\Output\en-US -Force
    }
}

# Invoke the build
Invoke-Build $Task
'@

    Set-Content -Path $buildScriptPath -Value $buildScriptContent
    Write-Status "Created build script template at: $buildScriptPath"

    # Create GitHub Actions workflow template
    $workflowsDir = Join-Path -Path $templatesDir -ChildPath "Workflows"
    if (-not (Test-Path -Path $workflowsDir)) {
        New-Item -Path $workflowsDir -ItemType Directory -Force | Out-Null
        Write-Status "Created workflows directory: $workflowsDir"
    }

    $workflowPath = Join-Path -Path $workflowsDir -ChildPath "powershell-ci.yml"
    $workflowContent = @'
name: PowerShell Module CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  test:
    name: Test on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [windows-latest]
        
    steps:
    - uses: actions/checkout@v2
    
    - name: Install dependencies
      shell: pwsh
      run: |
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module -Name Pester, PSScriptAnalyzer, InvokeBuild -Force
    
    - name: Run tests
      shell: pwsh
      run: |
        Invoke-Pester -Path ./Tests -CI
    
    - name: Run script analyzer
      shell: pwsh
      run: |
        $results = Invoke-ScriptAnalyzer -Path . -Recurse -ReportSummary
        $results | Format-Table
        if ($results.Where({$_.Severity -eq 'Error'})) {
          throw "Script analyzer found errors"
        }
    
    - name: Build module
      shell: pwsh
      run: |
        if (Test-Path -Path ./build.ps1) {
          ./build.ps1
        } else {
          Write-Host "No build script found, skipping build step"
        }
'@

    Set-Content -Path $workflowPath -Value $workflowContent
    Write-Status "Created GitHub Actions workflow template at: $workflowPath"

    # Create VSCode tasks template
    $vscodeTasks = @'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build",
            "type": "shell",
            "command": "Invoke-Build -Task Build",
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": []
        },
        {
            "label": "Test",
            "type": "shell",
            "command": "Invoke-Pester -Path ./Tests",
            "group": {
                "kind": "test",
                "isDefault": true
            },
            "problemMatcher": []
        },
        {
            "label": "Analyze",
            "type": "shell",
            "command": "Invoke-ScriptAnalyzer -Path . -Recurse",
            "problemMatcher": []
        },
        {
            "label": "Generate Documentation",
            "type": "shell",
            "command": "New-MarkdownHelp -Module YourModuleName -OutputFolder ./Docs -Force",
            "problemMatcher": []
        }
    ]
}
'@

    $vscodeDir = Join-Path -Path $templatesDir -ChildPath ".vscode"
    if (-not (Test-Path -Path $vscodeDir)) {
        New-Item -Path $vscodeDir -ItemType Directory -Force | Out-Null
        Write-Status "Created .vscode directory: $vscodeDir"
    }

    $tasksPath = Join-Path -Path $vscodeDir -ChildPath "tasks.json"
    Set-Content -Path $tasksPath -Value $vscodeTasks
    Write-Status "Created VSCode tasks template at: $tasksPath"

    # Create module manifest template
    $manifestTemplate = @'
@{
    RootModule = 'YourModuleName.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'New-Guid'
    Author = 'Your Name'
    CompanyName = 'Your Company'
    Copyright = '(c) 2025 Your Name. All rights reserved.'
    Description = 'Description of your module'
    PowerShellVersion = '7.0'
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @()
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = ''
        }
    }
}
'@

    $manifestPath = Join-Path -Path $templatesDir -ChildPath "module.psd1"
    Set-Content -Path $manifestPath -Value $manifestTemplate
    Write-Status "Created module manifest template at: $manifestPath"

    Write-Status "Environment configuration completed successfully"
}
catch {
    Write-Host "Error configuring environment: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    throw
}
