# Import the module before testing
Import-Module (Join-Path $PSScriptRoot '..\OSDCloudCustomBuilder.psd1') -Force

# Import test helper modules
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Admin-MockHelper.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Interactive-MockHelper.psm1') -Force

BeforeAll {
    # Set up admin context mock
    Set-TestAdminContext -IsAdmin $true

    # Initialize the logger
    Initialize-TestLogger
}

Describe "New-OSDCloudCustomMedia Tests" {
    BeforeEach {
        $TestPath = "$TestDrive\Media"

        # Mock directory creation instead of actually creating it
        Mock -CommandName New-Item -MockWith {
            return [PSCustomObject]@{
                FullName = $TestPath
            }
        }

        # Set up mocked parameters
        Set-MockedParameter -CommandName 'New-OSDCloudCustomMedia' -Parameters @{
            Name = 'TestMedia'
            Path = $TestPath
        }

        # Mock test for admin privileges
        Mock -CommandName Test-IsAdmin -MockWith { return $true }
    }

    It "Should create media in valid path" {
        { New-OSDCloudCustomMedia -Name 'TestMedia' -Path $TestPath } | Should -Not -Throw
    }

    It "Should fail on invalid path" {
        { New-OSDCloudCustomMedia -Path '' } | Should -Throw
    }
}
