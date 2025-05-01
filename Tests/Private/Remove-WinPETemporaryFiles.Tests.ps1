# File: Tests/Private/Remove-WinPETemporaryFiles.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Remove-WinPETemporaryFiles.ps1"

Describe 'Remove-WinPETemporaryFiles' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Remove-WinPETemporaryFiles } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Remove-WinPETemporaryFiles } | Should -Throw
        }
    }
}
