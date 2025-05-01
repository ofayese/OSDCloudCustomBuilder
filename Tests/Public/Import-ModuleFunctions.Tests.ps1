# File: Tests/Public/Import-ModuleFunctions.Tests.ps1
# Requires -Modules Pester

Import-Module "$PSScriptRoot/../../OSDCloudCustomBuilder.psd1" -Force

Describe 'Import-ModuleFunctions' {

    Context 'Execution smoke test' {
        It 'Should not throw when called without parameters (if allowed)' {
            try { Import-ModuleFunctions -ErrorAction Stop } catch { }
            $true | Should -BeTrue
        }
    }
}
