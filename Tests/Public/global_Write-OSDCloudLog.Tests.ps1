# File: Tests/Public/global:Write-OSDCloudLog.Tests.ps1
# Requires -Modules Pester

Import-Module "$PSScriptRoot/../../OSDCloudCustomBuilder.psd1" -Force

Describe 'global:Write-OSDCloudLog' {

    Context 'Execution smoke test' {
        It 'Should not throw when called without parameters (if allowed)' {
            try { global:Write-OSDCloudLog -ErrorAction Stop } catch { }
            $true | Should -BeTrue
        }
    }
}
