# Import Pester
Import-Module Pester -Force

# Import the module before testing
Import-Module (Join-Path $PSScriptRoot '..\OSDCloudCustomBuilder.psd1') -Force -ErrorAction Stop

Describe "Basic Module Tests" {
    BeforeAll {
        # Define a basic mock for Test-IsAdmin that returns true
        Mock -CommandName Test-IsAdmin -MockWith { return $true }
    }

    It "Should load the module correctly" {
        Get-Module -Name OSDCloudCustomBuilder | Should -Not -BeNullOrEmpty
    }
}
