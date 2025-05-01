# File: Tests/Private/Install-PowerShell7ToWinPE.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Install-PowerShell7ToWinPE.ps1"

Describe 'Install-PowerShell7ToWinPE' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Install-PowerShell7ToWinPE } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Install-PowerShell7ToWinPE } | Should -Throw
        }
    }
}
