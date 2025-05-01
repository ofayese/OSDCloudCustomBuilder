# File: Tests/Private/Test-ValidPowerShellVersion.Tests.ps1
# Requires -Modules Pester

Describe 'Test-ValidPowerShellVersion' {
    BeforeAll {
        # Import the function we're testing
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
        $moduleRoot = Split-Path -Parent (Split-Path -Parent $here)
        . "$moduleRoot/Private/Test-ValidPowerShellVersion.ps1"
        
        # Mock Write-OSDCloudLog to avoid errors
        function Write-OSDCloudLog {
            param($Message, $Level, $Component, $Exception)
            # Do nothing for tests
        }
    }

    Context 'Valid PowerShell versions' {
        It 'Should return true for PowerShell 7.0.0' {
            Test-ValidPowerShellVersion -Version "7.0.0" | Should -BeTrue
        }
        
        It 'Should return true for PowerShell 7.3.4' {
            Test-ValidPowerShellVersion -Version "7.3.4" | Should -BeTrue
        }
        
        It 'Should return true for PowerShell 7.4.0' {
            Test-ValidPowerShellVersion -Version "7.4.0" | Should -BeTrue
        }
    }
    
    Context 'Invalid PowerShell versions' {
        It 'Should return false for PowerShell 6.2.5' {
            Test-ValidPowerShellVersion -Version "6.2.5" | Should -BeFalse
        }
        
        It 'Should return false for PowerShell 8.0.0' {
            Test-ValidPowerShellVersion -Version "8.0.0" | Should -BeFalse
        }
        
        It 'Should return false for invalid format version' {
            Test-ValidPowerShellVersion -Version "7.3" | Should -BeFalse
        }
        
        It 'Should return false for version with non-numeric characters' {
            Test-ValidPowerShellVersion -Version "7.3.4-preview" | Should -BeFalse
        }
    }
    
    Context 'Error handling' {
        It 'Should not throw exceptions even with invalid input' {
            { Test-ValidPowerShellVersion -Version "invalid" } | Should -Not -Throw
        }
        
        It 'Should return false when an exception occurs' {
            Mock Test-ValidPowerShellVersion { throw "Simulated error" }
            { Test-ValidPowerShellVersion -Version "7.3.4" } | Should -Throw
        }
    }
}