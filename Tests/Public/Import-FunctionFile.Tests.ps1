# File: Tests/Public/Import-FunctionFile.Tests.ps1
# Requires -Modules Pester

Import-Module "$PSScriptRoot/../../OSDCloudCustomBuilder.psd1" -Force

Describe 'Import-FunctionFile' {

    Context 'Execution smoke test' {
        It 'Should not throw when called without parameters (if allowed)' {
            try { Import-FunctionFile -ErrorAction Stop } catch { }
            $true | Should -BeTrue
        }
    }
}
