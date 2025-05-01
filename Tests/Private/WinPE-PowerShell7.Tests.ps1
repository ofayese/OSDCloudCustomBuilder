# File: Tests/Private/WinPE-PowerShell7.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/WinPE-PowerShell7.ps1"

Describe 'WinPE-PowerShell7' {
    Context 'Basic behavior' {
        It 'Should run without throwing' {
            { WinPE-PowerShell7 } | Should -Not -Throw
        }
    }
}
