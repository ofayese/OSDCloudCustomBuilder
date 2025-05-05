# Test-Environment.ps1
# This script verifies that the development container is properly configured
# for OSDCloudCustomBuilder development

function Test-ModuleAvailability {
    param (
        [string]$ModuleName,
        [bool]$Required = $true
    )

    $module = Get-Module -Name $ModuleName -ListAvailable

    if ($module) {
        Write-Host "✅ $ModuleName module is available (v$($module.Version))" -ForegroundColor Green
        return $true
    }
    else {
        if ($Required) {
            Write-Host "❌ Required module $ModuleName is not available" -ForegroundColor Red
            return $false
        }
        else {
            Write-Host "⚠️ Optional module $ModuleName is not available" -ForegroundColor Yellow
            return $true
        }
    }
}

function Test-CommandAvailability {
    param (
        [string]$CommandName,
        [bool]$Required = $true
    )

    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue

    if ($command) {
        Write-Host "✅ $CommandName is available" -ForegroundColor Green
        return $true
    }
    else {
        if ($Required) {
            Write-Host "❌ Required command $CommandName is not available" -ForegroundColor Red
            return $false
        }
        else {
            Write-Host "⚠️ Optional command $CommandName is not available" -ForegroundColor Yellow
            return $true
        }
    }
}

function Test-FileAvailability {
    param (
        [string]$FilePath,
        [bool]$Required = $true
    )

    if (Test-Path -Path $FilePath) {
        Write-Host "✅ File exists: $FilePath" -ForegroundColor Green
        return $true
    }
    else {
        if ($Required) {
            Write-Host "❌ Required file not found: $FilePath" -ForegroundColor Red
            return $false
        }
        else {
            Write-Host "⚠️ Optional file not found: $FilePath" -ForegroundColor Yellow
            return $true
        }
    }
}

# Display environment information
Write-Host "`n=== Environment Information ===" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Host "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Host "Container User: $([System.Environment]::UserName)"
Write-Host "Working Directory: $((Get-Location).Path)"

# Test required PowerShell modules
Write-Host "`n=== PowerShell Modules ===" -ForegroundColor Cyan
$modulesOK = $true
$modulesOK = $modulesOK -and (Test-ModuleAvailability -ModuleName "Pester" -Required $true)
$modulesOK = $modulesOK -and (Test-ModuleAvailability -ModuleName "PSScriptAnalyzer" -Required $true)
$modulesOK = $modulesOK -and (Test-ModuleAvailability -ModuleName "ThreadJob" -Required $true)
$modulesOK = $modulesOK -and (Test-ModuleAvailability -ModuleName "OSDCloud" -Required $true)
$modulesOK = $modulesOK -and (Test-ModuleAvailability -ModuleName "OSD" -Required $true)

# Test required commands
Write-Host "`n=== Required Commands ===" -ForegroundColor Cyan
$commandsOK = $true
$commandsOK = $commandsOK -and (Test-CommandAvailability -CommandName "git" -Required $true)
$commandsOK = $commandsOK -and (Test-CommandAvailability -CommandName "DISM.exe" -Required $true)

# Test PowerShell 7 package
Write-Host "`n=== PowerShell 7 Package ===" -ForegroundColor Cyan
$ps7OK = Test-FileAvailability -FilePath "C:\OSDCloud\PowerShell-7.5.1-win-x64.zip" -Required $true

# Test Windows ADK installation
Write-Host "`n=== Windows ADK Installation ===" -ForegroundColor Cyan
$adkOK = $true
$adkOK = $adkOK -and (Test-Path -Path "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit")
if ($adkOK) {
    Write-Host "✅ Windows ADK is installed" -ForegroundColor Green
} else {
    Write-Host "❌ Windows ADK is not installed" -ForegroundColor Red
}

# Test Windows PE add-on installation
$adkPEOK = Test-Path -Path "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
if ($adkPEOK) {
    Write-Host "✅ Windows PE add-on is installed" -ForegroundColor Green
} else {
    Write-Host "❌ Windows PE add-on is not installed" -ForegroundColor Red
    $adkOK = $false
}

# Test workspace mounting
Write-Host "`n=== Workspace Mount ===" -ForegroundColor Cyan
$workspaceOK = Test-Path -Path "C:\workspace"
if ($workspaceOK) {
    Write-Host "✅ Workspace is mounted at C:\workspace" -ForegroundColor Green

    # Check if the module files are accessible
    if (Test-Path -Path "C:\workspace\OSDCloudCustomBuilder.psd1") {
        Write-Host "✅ Module manifest is accessible" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Module manifest is not accessible" -ForegroundColor Red
        $workspaceOK = $false
    }
}
else {
    Write-Host "❌ Workspace is not mounted at C:\workspace" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Environment Test Summary ===" -ForegroundColor Cyan
if ($modulesOK -and $commandsOK -and $ps7OK -and $workspaceOK -and $adkOK) {
    Write-Host "✅ Development container is properly configured for OSDCloudCustomBuilder development" -ForegroundColor Green
}
else {
    Write-Host "❌ Development container has configuration issues that need to be addressed" -ForegroundColor Red

    if (-not $modulesOK) {
        Write-Host "  - Some required PowerShell modules are missing" -ForegroundColor Red
    }

    if (-not $commandsOK) {
        Write-Host "  - Some required commands are missing" -ForegroundColor Red
    }

    if (-not $ps7OK) {
        Write-Host "  - PowerShell 7 package is missing" -ForegroundColor Red
    }

    if (-not $workspaceOK) {
        Write-Host "  - Workspace mounting issues detected" -ForegroundColor Red
    }

    if (-not $adkOK) {
        Write-Host "  - Windows ADK or Windows PE add-on is missing" -ForegroundColor Red
    }
}
