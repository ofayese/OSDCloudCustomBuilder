# File: Tests/Private/Invoke-OSDCloudLogger.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Invoke-OSDCloudLogger.ps1"

Describe 'Invoke-OSDCloudLogger' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Invoke-OSDCloudLogger } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Invoke-OSDCloudLogger } | Should -Throw
        }
    }
}
