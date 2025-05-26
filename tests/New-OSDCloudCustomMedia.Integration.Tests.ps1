# Import the module before testing
Import-Module (Join-Path $PSScriptRoot '..\OSDCloudCustomBuilder.psd1') -Force

Describe "New-OSDCloudCustomMedia Integration Tests" {
    Mock Test-Path { return $true }
    Mock Copy-Item { return $true }
    Mock New-Item { return $true }
    Mock Get-Content { return @("Mock Content") }

    It "Should create WinPE media without error" {
        { New-OSDCloudCustomMedia -Path "$TestDrive\Media" } | Should -Not -Throw
    }

    It "Should throw when path is invalid" {
        Mock Test-Path { return $false }
        { New-OSDCloudCustomMedia -Path "$TestDrive\BadMedia" } | Should -Throw
    }
}
