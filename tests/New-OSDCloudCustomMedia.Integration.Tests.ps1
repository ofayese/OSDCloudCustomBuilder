# Import the module before testing
Import-Module (Join-Path $PSScriptRoot '..\OSDCloudCustomBuilder.psd1') -Force -ErrorAction Stop

# Import test helper modules
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Admin-MockHelper.psm1') -Force -ErrorAction Stop
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Interactive-MockHelper.psm1') -Force -ErrorAction Stop

Describe "New-OSDCloudCustomMedia Integration Tests" {
    BeforeAll {
        # Set up admin context mock with explicit Admin privileges
        Set-TestAdminContext -IsAdmin $true

        # Initialize the logger
        Initialize-TestLogger

        # Define test paths
        $script:TestMediaPath = "C:\TestMedia"
        $script:TestName = "TestMedia"

        # Mock Test-IsAdmin explicitly for integration tests
        # This is important since integration tests may run in a different scope
        Mock -CommandName Test-IsAdmin -ModuleName OSDCloudCustomBuilder -MockWith { return $true }
        Mock -CommandName Test-IsAdmin -MockWith { return $true }

        # Mock filesystem functions
        Mock -CommandName Test-Path -MockWith { return $true }
        Mock -CommandName Copy-Item -MockWith { return $true }
        Mock -CommandName New-Item -MockWith { return $true }
        Mock -CommandName Get-Content -MockWith { return @("Mock Content") }

        # Mock environment initialization
        Mock -CommandName Initialize-OSDEnvironment -ModuleName OSDCloudCustomBuilder -MockWith { return $true }

        # Mock Test-ValidPath to avoid path validation issues
        Mock -CommandName Test-ValidPath -ModuleName OSDCloudCustomBuilder -MockWith {
            param($Path)
            return -not [string]::IsNullOrWhiteSpace($Path)
        }
    }

    It "Should create WinPE media without error" {
        { New-OSDCloudCustomMedia -Name $script:TestName -Path $script:TestMediaPath } | Should -Not -Throw
    }

    It "Should throw when path is invalid" {
        Mock -CommandName Test-ValidPath -ModuleName OSDCloudCustomBuilder -MockWith { return $false }
        { New-OSDCloudCustomMedia -Name $script:TestName -Path "$TestDrive\BadMedia" } | Should -Throw
    }
}
