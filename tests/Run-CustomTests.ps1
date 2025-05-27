# Custom test runner for OSDCloudCustomBuilder
# This script provides a simple way to test module functions without requiring Pester
param(
    [Parameter()]
    [ValidateSet('All', 'NewMedia', 'Driver', 'Script', 'Pwsh7')]
    [string]$TestType = 'All'
)

# Import required modules
$ModuleRoot = Split-Path -Parent $PSScriptRoot
Import-Module "$ModuleRoot\OSDCloudCustomBuilder.psd1" -Force
Import-Module "$PSScriptRoot\TestHelpers\Admin-MockHelper.psm1" -Force
Import-Module "$PSScriptRoot\TestHelpers\Interactive-MockHelper.psm1" -Force

# Set up common test environment
function Initialize-TestEnvironment {
    [CmdletBinding()]
    param()

    # Set admin context to true for all tests
    Set-TestAdminContext -IsAdmin $true -Verbose

    # Initialize logger
    Initialize-TestLogger -Verbose

    # Set up common test paths
    $script:TestPaths = @{
        MediaPath  = "C:\TestMedia"
        DriverPath = "C:\TestDrivers"
        ScriptPath = "C:\TestScripts"
        WimPath    = "C:\TestWim"
    }    # Initialize mock file system
    Initialize-FileSystemMocks -MockedDirectories @(
        $script:TestPaths.MediaPath,
        $script:TestPaths.DriverPath,
        $script:TestPaths.ScriptPath,
        $script:TestPaths.WimPath
    ) -MockedFiles @{
        "$($script:TestPaths.WimPath)\boot.wim"      = "Boot WIM Content"
        "$($script:TestPaths.WimPath)\install.wim"   = "Install WIM Content"
        "$($script:TestPaths.ScriptPath)\script.ps1" = "Script Content"
    }

    # Define common test output function
    function script:Test-Assert {
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

    # Common functions to mock
    Mock -CommandName Test-ValidPath -MockWith { param($Path) return -not [string]::IsNullOrWhiteSpace($Path) }
    Mock -CommandName Initialize-OSDEnvironment -MockWith { return $true }
    Mock -CommandName New-Item -MockWith {
        param($Path, $ItemType)
        return [PSCustomObject]@{
            PSPath        = "FileSystem::$Path"
            FullName      = $Path
            Exists        = $true
            PSIsContainer = ($ItemType -eq 'Directory')
        }
    }
    Mock -CommandName Copy-Item -MockWith { return $true }

    Write-Host "Test environment initialized successfully" -ForegroundColor Cyan
}

function Test-NewOSDCloudCustomMedia {
    [CmdletBinding()]
    param()

    Write-Host "`n=== Testing New-OSDCloudCustomMedia ===" -ForegroundColor Cyan

    # Set up test parameters
    $mediaName = "TestMedia"
    $mediaPath = $script:TestPaths.MediaPath

    # Test valid parameters
    try {
        New-OSDCloudCustomMedia -Name $mediaName -Path $mediaPath -ErrorAction Stop
        Test-Assert -Condition $true -Message "Created media with valid parameters" -TestName "New-OSDCloudCustomMedia"
    } catch {
        Test-Assert -Condition $false -Message "Failed to create media: $_" -TestName "New-OSDCloudCustomMedia"
    }

    # Test invalid parameters
    try {
        New-OSDCloudCustomMedia -Name $mediaName -Path "" -ErrorAction Stop
        Test-Assert -Condition $false -Message "Should have failed with empty path" -TestName "New-OSDCloudCustomMedia-InvalidPath"
    } catch {
        Test-Assert -Condition $true -Message "Correctly failed with empty path" -TestName "New-OSDCloudCustomMedia-InvalidPath"
    }
}

function Test-AddOSDCloudCustomDriver {
    [CmdletBinding()]
    param()

    Write-Host "`n=== Testing Add-OSDCloudCustomDriver ===" -ForegroundColor Cyan

    # Test parameters
    $driverPath = $script:TestPaths.DriverPath

    # Test valid path
    try {
        Add-OSDCloudCustomDriver -DriverPath $driverPath -ErrorAction Stop
        Test-Assert -Condition $true -Message "Added driver with valid path" -TestName "Add-OSDCloudCustomDriver"
    } catch {
        Test-Assert -Condition $false -Message "Failed to add driver: $_" -TestName "Add-OSDCloudCustomDriver"
    }

    # Test invalid path
    try {
        Add-OSDCloudCustomDriver -DriverPath "" -ErrorAction Stop
        Test-Assert -Condition $false -Message "Should have failed with empty path" -TestName "Add-OSDCloudCustomDriver-InvalidPath"
    } catch {
        Test-Assert -Condition $true -Message "Correctly failed with empty path" -TestName "Add-OSDCloudCustomDriver-InvalidPath"
    }
}

# Set verbose debugging output
$VerbosePreference = "Continue"

try {
    # Verify Test-IsAdmin is working
    Write-Host "Testing admin status:" -ForegroundColor Cyan
    try {
        $isAdmin = Test-IsAdmin
        Write-Host "Test-IsAdmin returns: $isAdmin" -ForegroundColor Cyan
    } catch {
        Write-Host "Error calling Test-IsAdmin: $_" -ForegroundColor Red
        # Check if the function is available
        if (Get-Command -Name Test-IsAdmin -ErrorAction SilentlyContinue) {
            Write-Host "Test-IsAdmin function is available" -ForegroundColor Yellow
        } else {
            Write-Host "Test-IsAdmin function is NOT available" -ForegroundColor Red
        }
    }

    # Initialize test environment
    Initialize-TestEnvironment

    # Run appropriate tests based on test type
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
