# File: Tests/Private/Test-WimFileAccessible.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Test-WimFileAccessible.ps1"

Describe 'Test-WimFileAccessible' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Test-WimFileAccessible } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Test-WimFileAccessible } | Should -Throw
        }
    }
}
