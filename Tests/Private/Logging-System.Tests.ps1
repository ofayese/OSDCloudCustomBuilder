# File: Tests/Private/Logging-System.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Logging-System.ps1"

Describe 'Logging-System' {
    Context 'Basic behavior' {
        It 'Should run without throwing' {
            { Logging-System } | Should -Not -Throw
        }
    }
}
