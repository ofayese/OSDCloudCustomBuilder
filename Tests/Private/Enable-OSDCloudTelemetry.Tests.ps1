# File: Tests/Private/Enable-OSDCloudTelemetry.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Enable-OSDCloudTelemetry.ps1"

Describe 'Enable-OSDCloudTelemetry' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Enable-OSDCloudTelemetry } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Enable-OSDCloudTelemetry } | Should -Throw
        }
    }
}
