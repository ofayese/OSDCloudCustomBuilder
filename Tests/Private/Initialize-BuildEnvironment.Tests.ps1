# File: Tests/Private/Initialize-BuildEnvironment.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Initialize-BuildEnvironment.ps1"

Describe 'Initialize-BuildEnvironment' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Initialize-BuildEnvironment } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Initialize-BuildEnvironment } | Should -Throw
        }
    }
}
