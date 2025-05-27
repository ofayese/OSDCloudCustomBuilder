# Import the module before testing
Import-Module (Join-Path $PSScriptRoot '..\OSDCloudCustomBuilder.psd1') -Force -ErrorAction Stop

# Import test helper modules
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Admin-MockHelper.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Interactive-MockHelper.psm1') -Force

BeforeAll {
    # Set up admin context mock with explicit Admin privileges
    Set-TestAdminContext -IsAdmin $true

    # Initialize the logger properly with module context
    Initialize-TestLogger

    # Define test paths that will be used in multiple tests - use an actual path
    $script:TestMediaPath = "C:\TestMedia"
    $script:TestName = "TestMedia"

    # Initialize mock file system with our test paths
    Initialize-MockFileSystem -MockedDirectories @(
        $script:TestMediaPath,
        "C:\TestWim",
        "C:\TestDrivers"
    ) -MockedFiles @(
        "C:\TestWim\boot.wim",
        "C:\TestWim\install.wim"
    )

    # Mock the Test-IsAdmin function directly to ensure it works
    # This is an extra safety measure in case Set-TestAdminContext doesn't work
    Mock -CommandName Test-IsAdmin -ModuleName OSDCloudCustomBuilder -MockWith {
        return $true
    }
}

Describe "New-OSDCloudCustomMedia Tests" {
    BeforeEach {
        # Set up mocked parameters
        Set-MockedParameter -CommandName 'New-OSDCloudCustomMedia' -Parameters @{
            Name = $script:TestName
            Path = $script:TestMediaPath
        }

        # Additional mocks for specific functions used in New-OSDCloudCustomMedia
        Mock -CommandName Test-ValidPath -ModuleName OSDCloudCustomBuilder -MockWith {
            param($Path)
            return -not [string]::IsNullOrWhiteSpace($Path)
        }

        # Mock environment initialization
        Mock -CommandName Initialize-OSDEnvironment -ModuleName OSDCloudCustomBuilder -MockWith {
            # Return a successful initialization result
            return $true
        }

        # Mock common file operations
        Mock -CommandName New-Item -ModuleName OSDCloudCustomBuilder -MockWith {
            param($Path, $ItemType)

            # Return a mock directory or file object as appropriate
            if ($ItemType -eq 'Directory') {
                return [PSCustomObject]@{
                    PSPath        = "Microsoft.PowerShell.Core\FileSystem::$Path"
                    FullName      = $Path
                    Exists        = $true
                    PSIsContainer = $true
                }
            } else {
                return [PSCustomObject]@{
                    PSPath        = "Microsoft.PowerShell.Core\FileSystem::$Path"
                    FullName      = $Path
                    Exists        = $true
                    PSIsContainer = $false
                }
            }
        }

        # Mock Copy-Item
        Mock -CommandName Copy-Item -ModuleName OSDCloudCustomBuilder -MockWith {
            # Just return success
            return $true
        }
    }

    It "Should create media in valid path" {
        # Define valid parameters
        $validParams = @{
            Name = $script:TestName
            Path = $script:TestMediaPath
        }

        # Debug parameter values
        Write-Host "DEBUG: TestName = $($script:TestName)" -ForegroundColor Cyan
        Write-Host "DEBUG: TestMediaPath = $($script:TestMediaPath)" -ForegroundColor Cyan

        # Test with direct parameters instead of splatting
        { New-OSDCloudCustomMedia -Name $script:TestName -Path $script:TestMediaPath } | Should -Not -Throw
    }

    It "Should fail on invalid path" {
        # Test with invalid empty path parameter
        { New-OSDCloudCustomMedia -Name 'TestMedia' -Path '' } | Should -Throw
    }
}
