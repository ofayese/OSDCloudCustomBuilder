# File: Tests/Private/Export-SecureOSDCloudConfig.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Export-SecureOSDCloudConfig.ps1"

Describe 'Export-SecureOSDCloudConfig' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { Export-SecureOSDCloudConfig } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { Export-SecureOSDCloudConfig } | Should -Throw
        }
    }
}
