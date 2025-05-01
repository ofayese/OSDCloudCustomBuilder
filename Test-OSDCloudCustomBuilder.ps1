<#
.SYNOPSIS
    Comprehensive test script to validate the OSDCloudCustomBuilder module functionality.
.DESCRIPTION
    This script tests the core functionality of the OSDCloudCustomBuilder module by:
    1. Importing the module
    2. Testing key public functions
    3. Validating configuration settings
    4. Verifying PowerShell 7 content wrapping
    5. Checking module information and version
.NOTES
    Version: 2.0
    Author: Oluwaseun Fayese
    Date: April 20, 2025
#>

# Ensure any errors will stop execution
$ErrorActionPreference = 'Stop'
Write-Host "Starting OSDCloudCustomBuilder module validation..." -ForegroundColor Cyan

# Step 1: Import the module
Write-Host "`n[Step 1] Importing module..." -ForegroundColor Green
try {
    Import-Module OSDCloudCustomBuilder -Force
    $moduleInfo = Get-Module OSDCloudCustomBuilder
    Write-Host "✅ Module imported successfully" -ForegroundColor Green
    Write-Host "   Module Version: $($moduleInfo.Version)" -ForegroundColor Green
    Write-Host "   Module Path: $($moduleInfo.Path)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to import module: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Check available commands
Write-Host "`n[Step 2] Checking exported functions..." -ForegroundColor Green
$commands = Get-Command -Module OSDCloudCustomBuilder
Write-Host "Found $($commands.Count) commands in the module:" -ForegroundColor Yellow
$commands | Sort-Object Name | ForEach-Object { Write-Host "  - $($_.Name)" }

# Step 3: Test PowerShell 7 content wrapping
Write-Host "`n[Step 3] Testing PowerShell 7 content wrapping..." -ForegroundColor Green
try {
    $testContent = 'Write-Host "Hello from PowerShell 7"'
    $wrappedContent = Get-PWsh7WrappedContent -Content $testContent
    Write-Host "Original content: $testContent" -ForegroundColor Yellow
    Write-Host "Wrapped content sample:" -ForegroundColor Yellow
    $wrappedContent.Split("`n") | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
    Write-Host "  ... (truncated)" -ForegroundColor Gray
    
    # Test with error handling
    $wrappedWithErrorHandling = Get-PWsh7WrappedContent -Content $testContent -AddErrorHandling
    Write-Host "With error handling (first 5 lines):" -ForegroundColor Yellow
    $wrappedWithErrorHandling.Split("`n") | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
    Write-Host "  ... (truncated)" -ForegroundColor Gray
    
    # Test with logging
    $wrappedWithLogging = Get-PWsh7WrappedContent -Content $testContent -AddLogging
    Write-Host "With logging (first 5 lines):" -ForegroundColor Yellow
    $wrappedWithLogging.Split("`n") | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
    Write-Host "  ... (truncated)" -ForegroundColor Gray
    
    Write-Host "✅ Content wrapping successful" -ForegroundColor Green
}
catch {
    Write-Host "❌ Content wrapping failed: $_" -ForegroundColor Red
}

# Step 4: Test configuration settings
Write-Host "`n[Step 4] Testing configuration settings..." -ForegroundColor Green
try {
    # Create a test config
    $testConfig = @{
        PowerShell7 = @{
            Version = "7.5.0"
            CacheEnabled = $true
            Logging = @{
                DefaultPath = "X:\OSDCloud\Logs"
                IncludeTimestamp = $true
                DefaultLevel = "Info"
            }
        }
        Paths = @{
            WorkingDirectory = "$env:TEMP\OSDCloudTest"
            Cache = "$env:TEMP\OSDCloudCache"
            Logs = "$env:TEMP\OSDCloudLogs"
        }
        Timeouts = @{
            Download = 600
            Mount = 300
            Dismount = 300
            Job = 300
        }
        Telemetry = @{
            Enabled = $false
            Path = "$env:TEMP\OSDCloudTelemetry"
            RetentionDays = 30
        }
    }
    
    Write-Host "Test configuration:" -ForegroundColor Yellow
    $testConfig.Keys | ForEach-Object {
        $key = $_
        Write-Host "  $key:" -ForegroundColor Yellow
        $testConfig[$key].Keys | ForEach-Object {
            $subKey = $_
            $value = $testConfig[$key][$subKey]
            if ($value -is [hashtable]) {
                Write-Host "    $subKey: [Hashtable with $(($value.Keys).Count) keys]" -ForegroundColor Yellow
            } else {
                Write-Host "    $subKey: $value" -ForegroundColor Yellow
            }
        }
    }
    
    Set-OSDCloudCustomBuilderConfig -Config $testConfig -WhatIf
    Write-Host "✅ Configuration test successful" -ForegroundColor Green
}
catch {
    Write-Host "❌ Configuration test failed: $_" -ForegroundColor Red
}

# Step 5: Check for required dependencies
Write-Host "`n[Step 5] Checking for required dependencies..." -ForegroundColor Green

# Check for DISM module
if (Get-Module -Name DISM -ListAvailable) {
    Write-Host "✅ DISM module is available" -ForegroundColor Green
} else {
    Write-Host "⚠️ DISM module not found. Some functions may not work properly." -ForegroundColor Yellow
}

# Check for ThreadJob module
if (Get-Module -Name ThreadJob -ListAvailable) {
    Write-Host "✅ ThreadJob module is available" -ForegroundColor Green
} else {
    Write-Host "⚠️ ThreadJob module not found. Parallel processing will use standard jobs." -ForegroundColor Yellow
}

# Check for Pester module
$pesterModule = Get-Module -Name Pester -ListAvailable | 
                Sort-Object -Property Version -Descending | 
                Select-Object -First 1
if ($pesterModule -and $pesterModule.Version.Major -ge 5) {
    Write-Host "✅ Pester v$($pesterModule.Version) is available" -ForegroundColor Green
} else {
    Write-Host "⚠️ Pester 5.0 or higher not found. Tests may not run properly." -ForegroundColor Yellow
}

# Step 6: Verify module structure
Write-Host "`n[Step 6] Verifying module structure..." -ForegroundColor Green
$moduleRoot = (Get-Module OSDCloudCustomBuilder).ModuleBase
$publicFunctions = Get-ChildItem -Path "$moduleRoot\Public" -Filter "*.ps1" -ErrorAction SilentlyContinue
$privateFunctions = Get-ChildItem -Path "$moduleRoot\Private" -Filter "*.ps1" -ErrorAction SilentlyContinue

Write-Host "Module structure:" -ForegroundColor Yellow
Write-Host "  - Public functions: $($publicFunctions.Count)" -ForegroundColor Yellow
Write-Host "  - Private functions: $($privateFunctions.Count)" -ForegroundColor Yellow

# Step 7: Run a simple validation test
Write-Host "`n[Step 7] Running validation tests..." -ForegroundColor Green
try {
    # Test PowerShell version validation
    $validVersion = "7.5.0"
    $invalidVersion = "6.0.0"
    
    $validResult = Test-ValidPowerShellVersion -Version $validVersion
    $invalidResult = Test-ValidPowerShellVersion -Version $invalidVersion
    
    Write-Host "PowerShell version validation:" -ForegroundColor Yellow
    Write-Host "  - Version $validVersion is valid: $validResult" -ForegroundColor $(if ($validResult) { "Green" } else { "Red" })
    Write-Host "  - Version $invalidVersion is valid: $invalidResult" -ForegroundColor $(if (-not $invalidResult) { "Green" } else { "Red" })
    
    if ($validResult -and -not $invalidResult) {
        Write-Host "✅ Validation tests passed" -ForegroundColor Green
    } else {
        Write-Host "❌ Validation tests failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Validation tests failed: $_" -ForegroundColor Red
}

Write-Host "`n✅ OSDCloudCustomBuilder module validation completed!" -ForegroundColor Green
Write-Host "To run the full test suite, use: .\Run-Tests.ps1" -ForegroundColor Cyan