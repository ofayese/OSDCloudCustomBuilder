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
}

Describe "Module Mocking Tests" {
    It "Should mock Test-IsAdmin to return true" {
        # Test that the Test-IsAdmin mock is working
        $moduleSession = Get-Module -Name OSDCloudCustomBuilder

        # Invoke the function inside the module
        $result = $moduleSession.Invoke({
                # Test-IsAdmin is a private function, but it should be available in the module context
                Test-IsAdmin
            })

        $result | Should -Be $true
    }

    It "Should initialize logger correctly" {
        # Test that the logger is initialized
        $moduleSession = Get-Module -Name OSDCloudCustomBuilder

        # Check that the logger variables exist
        $cacheInitialized = $moduleSession.Invoke({
                [bool]$script:OSDCloudLogger_CacheInitialized
            })

        $cacheInitialized | Should -Be $true
    }
}
