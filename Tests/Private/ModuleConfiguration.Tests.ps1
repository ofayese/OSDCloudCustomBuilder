# File: Tests/Private/ModuleConfiguration.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/ModuleConfiguration.ps1"

Describe 'ModuleConfiguration' {
    Context 'Basic behavior' {
        It 'Should run without throwing' {
            { ModuleConfiguration } | Should -Not -Throw
        }
    }
}
