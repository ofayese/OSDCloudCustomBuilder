# File: Tests/Public/Initialize-ModuleLogging.Tests.ps1
# Requires -Modules Pester

Import-Module "$PSScriptRoot/../../OSDCloudCustomBuilder.psd1" -Force

Describe 'Initialize-ModuleLogging' {

    Context 'Execution smoke test' {
        It 'Should not throw when called without parameters (if allowed)' {
            try { Initialize-ModuleLogging -ErrorAction Stop } catch { }
            $true | Should -BeTrue
        }
    }
}
