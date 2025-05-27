# Import the module before testing
Import-Module (Join-Path $PSScriptRoot '..\OSDCloudCustomBuilder.psd1') -Force

# Import test helper modules
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Admin-MockHelper.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Interactive-MockHelper.psm1') -Force

BeforeAll {
    # Set up admin context mock with explicit Admin privileges
    Set-TestAdminContext -IsAdmin $true

    # Initialize the logger properly with module context
    Initialize-TestLogger

    # Define test paths that will be used in multiple tests
    $script:TestMediaPath = "TestDrive:\Media"
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
                    PSPath = "Microsoft.PowerShell.Core\FileSystem::$Path"
                    FullName = $Path
                    Exists = $true
                    PSIsContainer = $true
                }
            } else {
                return [PSCustomObject]@{
                    PSPath = "Microsoft.PowerShell.Core\FileSystem::$Path"
                    FullName = $Path
                    Exists = $true
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
        { New-OSDCloudCustomMedia -Name 'TestMedia' -Path $TestPath } | Should -Not -Throw
    }

    It "Should fail on invalid path" {
        { New-OSDCloudCustomMedia -Path '' } | Should -Throw
    }
}
