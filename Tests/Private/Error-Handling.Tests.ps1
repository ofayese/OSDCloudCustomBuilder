# File: Tests/Private/Error-Handling.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Error-Handling.ps1"

Describe 'Error-Handling' {
    Context 'Basic behavior' {
        It 'Should run without throwing' {
            { Error-Handling } | Should -Not -Throw
        }
    }
}
