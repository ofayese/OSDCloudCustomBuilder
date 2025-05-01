# File: Tests/Private/Initialize-WinPEMountPoint.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Initialize-WinPEMountPoint.ps1"

Describe 'Initialize-WinPEMountPoint' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Initialize-WinPEMountPoint } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Initialize-WinPEMountPoint } | Should -Throw
        }
    }
}
