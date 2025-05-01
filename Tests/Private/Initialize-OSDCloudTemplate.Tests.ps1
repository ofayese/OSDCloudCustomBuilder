# File: Tests/Private/Initialize-OSDCloudTemplate.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Initialize-OSDCloudTemplate.ps1"

Describe 'Initialize-OSDCloudTemplate' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Initialize-OSDCloudTemplate } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Initialize-OSDCloudTemplate } | Should -Throw
        }
    }
}
