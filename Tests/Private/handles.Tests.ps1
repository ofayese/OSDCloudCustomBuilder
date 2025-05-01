# File: Tests/Private/handles.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/handles.ps1"

Describe 'handles' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { handles } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { handles } | Should -Throw
        }
    }
}
