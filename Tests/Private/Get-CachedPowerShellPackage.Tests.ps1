# File: Tests/Private/Get-CachedPowerShellPackage.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Get-CachedPowerShellPackage.ps1"

Describe 'Get-CachedPowerShellPackage' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Get-CachedPowerShellPackage } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Get-CachedPowerShellPackage } | Should -Throw
        }
    }
}
