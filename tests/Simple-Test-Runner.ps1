# Custom test runner without Pester dependencies
# This script tests the OSDCloudCustomBuilder module by directly overriding functions
param(
    [Parameter()]
    [ValidateSet('All', 'NewMedia', 'Driver', 'Script', 'Pwsh7')]
    [string]$TestType = 'All'
)

# Set verbose output
$VerbosePreference = "Continue"

# Import the module
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) "OSDCloudCustomBuilder.psd1") -Force

# Create our own test environment
$script:TestPaths = @{
    MediaPath  = "C:\TestMedia"
    DriverPath = "C:\TestDrivers"
    ScriptPath = "C:\TestScripts"
    WimPath    = "C:\TestWim"
}

# Override the Test-IsAdmin function
function global:Test-IsAdmin {
    # Always return true for tests
    return $true
}

# Override other functions used by the module
function global:Test-ValidPath {
    param($Path)

    # Consider any non-empty path as valid
    return -not [string]::IsNullOrWhiteSpace($Path)
}

function global:Initialize-OSDEnvironment {
    # Return success
    return $true
}

function global:Invoke-OSDCloudLogger {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info',

        [Parameter()]
        [string]$Component = 'Test'
    )

    # Just output to console for tests
    Write-Host "[$Level] [$Component] $Message"
}

# Override file system cmdlets
function global:Test-Path {
    param($Path, $PathType)

    # Consider test paths as existing
    $testDirs = @(
        $script:TestPaths.MediaPath,
        $script:TestPaths.DriverPath,
        $script:TestPaths.ScriptPath,
        $script:TestPaths.WimPath
    )

    $testFiles = @(
        "$($script:TestPaths.WimPath)\boot.wim",
        "$($script:TestPaths.WimPath)\install.wim",
        "$($script:TestPaths.ScriptPath)\script.ps1"
    )

    if ($PathType -eq 'Leaf') {
        return $testFiles -contains $Path
    } elseif ($PathType -eq 'Container') {
        return $testDirs -contains $Path
    } else {
        return ($testDirs -contains $Path) -or ($testFiles -contains $Path)
    }
}

function global:New-Item {
    param($Path, $ItemType)

    # Return a mock object
    return [PSCustomObject]@{
        PSPath        = "FileSystem::$Path"
        FullName      = $Path
        Exists        = $true
        PSIsContainer = ($ItemType -eq 'Directory')
    }
}

function global:Copy-Item {
    param($Path, $Destination)

    # Do nothing in tests, just return true
    return $true
}

# Test assertion function
function Test-Assert {
    param (
        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$TestName = "Unnamed Test"
    )

    if ($Condition) {
        Write-Host "✓ PASS: $TestName - $Message" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ FAIL: $TestName - $Message" -ForegroundColor Red
        return $false
    }
}

# Test functions
function Test-NewOSDCloudCustomMedia {
    Write-Host "`n=== Testing New-OSDCloudCustomMedia ===" -ForegroundColor Cyan

    # Test valid parameters
    try {
        $result = New-OSDCloudCustomMedia -Name "TestMedia" -Path $script:TestPaths.MediaPath -ErrorAction Stop
        Test-Assert -Condition ($null -ne $result) -Message "Created media with valid parameters" -TestName "New-OSDCloudCustomMedia"
    } catch {
        Test-Assert -Condition $false -Message "Failed to create media: $_" -TestName "New-OSDCloudCustomMedia"
    }
}

function Test-AddOSDCloudCustomDriver {
    Write-Host "`n=== Testing Add-OSDCloudCustomDriver ===" -ForegroundColor Cyan

    # Test valid parameters
    try {
        $result = Add-OSDCloudCustomDriver -DriverPath $script:TestPaths.DriverPath -ErrorAction Stop
        Test-Assert -Condition ($null -ne $result) -Message "Added driver with valid path" -TestName "Add-OSDCloudCustomDriver"
    } catch {
        Test-Assert -Condition $false -Message "Failed to add driver: $_" -TestName "Add-OSDCloudCustomDriver"
    }
}

# Main test execution
Write-Host "Starting OSDCloudCustomBuilder module tests..." -ForegroundColor Cyan

# Run appropriate tests based on test type
try {
    switch ($TestType) {
        'All' {
            Test-NewOSDCloudCustomMedia
            Test-AddOSDCloudCustomDriver
        }
        'NewMedia' {
            Test-NewOSDCloudCustomMedia
        }
        'Driver' {
            Test-AddOSDCloudCustomDriver
        }
        default {
            Write-Host "No tests selected to run" -ForegroundColor Yellow
        }
    }

    Write-Host "`nAll tests completed!" -ForegroundColor Cyan
} catch {
    Write-Host "Error in test execution: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
