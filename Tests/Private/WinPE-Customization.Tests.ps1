# File: Tests/Private/WinPE-Customization.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/WinPE-Customization.ps1"

Describe 'WinPE-Customization' {
    Context 'Basic behavior' {
        It 'Should run without throwing' {
            { WinPE-Customization } | Should -Not -Throw
        }
    }
}
