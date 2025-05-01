# File: Tests/Private/Validation-Helpers.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Validation-Helpers.ps1"

Describe 'Validation-Helpers' {
    Context 'Basic behavior' {
        It 'Should run without throwing' {
            { Validation-Helpers } | Should -Not -Throw
        }
    }
}
