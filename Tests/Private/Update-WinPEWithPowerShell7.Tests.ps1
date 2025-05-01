# File: Tests/Private/Update-WinPEWithPowerShell7.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Update-WinPEWithPowerShell7.ps1"

Describe 'Update-WinPEWithPowerShell7' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Update-WinPEWithPowerShell7 } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Update-WinPEWithPowerShell7 } | Should -Throw
        }
    }
}
