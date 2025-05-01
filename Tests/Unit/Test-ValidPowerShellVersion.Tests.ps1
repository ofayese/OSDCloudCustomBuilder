# File: Tests/Unit/Test-ValidPowerShellVersion.Tests.ps1
Set-StrictMode -Version Latest

Describe "Test-ValidPowerShellVersion Unit Tests" {
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
    
    Context "Version format validation" {
        It "Should return true for valid version format" {
            Test-ValidPowerShellVersion -Version "7.3.4" | Should -BeTrue
        }
        
        It "Should return false for invalid version format" {
            Test-ValidPowerShellVersion -Version "7.3" | Should -BeFalse
            Test-ValidPowerShellVersion -Version "7" | Should -BeFalse
            Test-ValidPowerShellVersion -Version "7.3.4.5" | Should -BeFalse
            Test-ValidPowerShellVersion -Version "invalid" | Should -BeFalse
        }
    }
    
    Context "Major version validation" {
        It "Should return true for PowerShell 7.x versions" {
            Test-ValidPowerShellVersion -Version "7.0.0" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.1.0" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.2.0" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.3.0" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.4.0" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.5.0" | Should -BeTrue
        }
        
        It "Should return false for non-PowerShell 7 versions" {
            Test-ValidPowerShellVersion -Version "5.1.0" | Should -BeFalse
            Test-ValidPowerShellVersion -Version "6.2.0" | Should -BeFalse
            Test-ValidPowerShellVersion -Version "8.0.0" | Should -BeFalse
        }
    }
    
    Context "Minor version validation" {
        It "Should return true for supported minor versions" {
            Test-ValidPowerShellVersion -Version "7.0.0" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.1.0" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.2.0" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.3.0" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.4.0" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.5.0" | Should -BeTrue
        }
        
        It "Should return false for unsupported minor versions" {
            Test-ValidPowerShellVersion -Version "7.6.0" | Should -BeFalse
            Test-ValidPowerShellVersion -Version "7.9.0" | Should -BeFalse
        }
    }
    
    Context "Patch version handling" {
        It "Should accept any patch version for supported major.minor versions" {
            Test-ValidPowerShellVersion -Version "7.3.0" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.3.1" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.3.2" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.3.3" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.3.4" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.3.5" | Should -BeTrue
            Test-ValidPowerShellVersion -Version "7.3.9" | Should -BeTrue
        }
    }
    
    Context "Error handling" {
        It "Should handle exceptions gracefully" {
            # Mock the version regex check to throw an exception
            Mock -CommandName [regex]::IsMatch { throw "Simulated error" }
            
            # Should return false and not throw
            { Test-ValidPowerShellVersion -Version "7.3.4" } | Should -Not -Throw
            Test-ValidPowerShellVersion -Version "7.3.4" | Should -BeFalse
        }
    }
}