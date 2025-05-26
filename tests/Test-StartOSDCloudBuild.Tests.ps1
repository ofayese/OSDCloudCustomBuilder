# Import the module before testing
Import-Module (Join-Path $PSScriptRoot '..\OSDCloudCustomBuilder.psd1') -Force

Describe 'OSDCloudCustomBuilder Functions' {
    It 'Test-OSDCloudCustomRequirements should exist' {
        Get-Command -Name Test-OSDCloudCustomRequirements -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'New-OSDCloudCustomMedia should exist' {
        Get-Command -Name New-OSDCloudCustomMedia -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
