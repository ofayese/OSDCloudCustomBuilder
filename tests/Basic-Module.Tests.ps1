# Import Pester
Import-Module Pester -Force

# Import the module before testing
Import-Module (Join-Path $PSScriptRoot '..\OSDCloudCustomBuilder.psd1') -Force -ErrorAction Stop

# Import test helper modules
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Admin-MockHelper.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Interactive-MockHelper.psm1') -Force

Describe "Basic Module Tests" {
    BeforeAll {
        # Set up admin context mock with explicit Admin privileges
        Set-TestAdminContext -IsAdmin $true

        # Initialize the logger properly with module context
        Initialize-TestLogger
    }

    It "Should load the module correctly" {
        Get-Module -Name OSDCloudCustomBuilder | Should -Not -BeNullOrEmpty
    }
}
