# Tests for OSDCloudCustomBuilder Module
Describe 'OSDCloudCustomBuilder Module' {
    Context 'Module Import' {
        It 'should import without errors' {
            { Import-Module OSDCloudCustomBuilder -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It 'should expose expected commands' {
            $commands = Get-Command -Module OSDCloudCustomBuilder
            $commands | Should -Not -BeNullOrEmpty
        }
    }

    Context 'PowerShell 7 Wrapping Function' {
        It 'should wrap content without error' {
            $wrapped = Get-PWsh7WrappedContent -Content 'echo hello'
            $wrapped | Should -Match 'Write-Output'
        }

        It 'should add error handling if requested' {
            $wrapped = Get-PWsh7WrappedContent -Content 'echo hello' -AddErrorHandling
            $wrapped | Should -Match 'try'
        }

        It 'should add logging if requested' {
            $wrapped = Get-PWsh7WrappedContent -Content 'echo hello' -AddLogging
            $wrapped | Should -Match 'Write-Log'
        }
    }

    Context 'Configuration Handling' {
        It 'should accept test configuration without error' {
            $testConfig = @{
                PowerShell7 = @{
                    Version = "7.5.0"
                    CacheEnabled = $true
                }
                Paths = @{
                    WorkingDirectory = "$env:TEMP\OSDCloudTest"
                }
            }
            { Set-OSDCloudCustomBuilderConfig -Config $testConfig -WhatIf } | Should -Not -Throw
        }
    }

    Context 'PowerShell Version Validation' {
        It 'should validate correct version' {
            Test-ValidPowerShellVersion -Version '7.5.0' | Should -Be $true
        }

        It 'should invalidate older version' {
            Test-ValidPowerShellVersion -Version '6.0.0' | Should -Be $false
        }
    }
}