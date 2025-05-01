# File: Tests/Private/OSDCloudConfig.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/OSDCloudConfig.ps1"

Describe 'OSDCloudConfig' {
    Context 'Basic behavior' {
        It 'Should run without throwing' {
            { OSDCloudConfig } | Should -Not -Throw
        }
    }
}
