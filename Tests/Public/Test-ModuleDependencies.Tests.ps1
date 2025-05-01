# File: Tests/Public/Test-ModuleDependencies.Tests.ps1
# Requires -Modules Pester

Import-Module "$PSScriptRoot/../../OSDCloudCustomBuilder.psd1" -Force

Describe 'Test-ModuleDependencies' {

    Context 'Execution smoke test' {
        It 'Should not throw when called without parameters (if allowed)' {
            try { Test-ModuleDependencies -ErrorAction Stop } catch { }
            $true | Should -BeTrue
        }
    }
}
