# File: Tests/Private/Get-PWsh7WrappedContent.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Get-PWsh7WrappedContent.ps1"

Describe 'Get-PWsh7WrappedContent' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Get-PWsh7WrappedContent } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Get-PWsh7WrappedContent } | Should -Throw
        }
    }
}
