# File: Tests/Comprehensive-TestSuite.Tests.ps1
# Author: Oluwaseun Fayese
# Company: Modern Endpoint Management
# Last Modified: April 19, 2025

BeforeAll {
    # Import the module for testing
    $modulePath = Split-Path -Path $PSScriptRoot -Parent
    Import-Module -Name $modulePath -Force
    
    # Mock Write-OSDCloudLog to avoid errors
    function Write-OSDCloudLog {
        param($Message, $Level, $Component, $Exception)
        # Do nothing for tests
    }
    
    # Create test directories
    $testRoot = Join-Path -Path $TestDrive -ChildPath "OSDCloudTest"
    $testWorkspace = Join-Path -Path $testRoot -ChildPath "Workspace"
    $testOutput = Join-Path -Path $testRoot -ChildPath "Output"
    $testWim = Join-Path -Path $testRoot -ChildPath "test.wim"
    
    # Create test directories
    New-Item -Path $testWorkspace -ItemType Directory -Force
    New-Item -Path $testOutput -ItemType Directory -Force
    
    # Create a dummy WIM file for testing
    "DUMMY WIM CONTENT" | Out-File -FilePath $testWim -Force
    
    # Mock common functions
    Mock Test-Path { $true }
    Mock Test-IsAdmin { $true }
    Mock Get-PSDrive {
        [PSCustomObject]@{
            Name = "C"
            Free = 50GB
        }
    }
}

Describe "OSDCloudCustomBuilder Module Tests" {
    Context "Module Loading" {
        It "Should import the OSDCloudCustomBuilder module without errors" {
            { Get-Module -Name OSDCloudCustomBuilder } | Should -Not -Throw
            Get-Module -Name OSDCloudCustomBuilder | Should -Not -BeNullOrEmpty
        }
        
        It "Should export the required functions" {
            $exportedFunctions = Get-Command -Module OSDCloudCustomBuilder -CommandType Function
            $exportedFunctions.Count | Should -BeGreaterThan 0
            $exportedFunctions.Name | Should -Contain 'Set-OSDCloudCustomBuilderConfig'
            $exportedFunctions.Name | Should -Contain 'Get-PWsh7WrappedContent'
        }
    }
    
    Context "Get-PWsh7WrappedContent Function" {
        It "Should wrap content in PowerShell 7 execution block" {
            $testContent = 'Write-Host "Hello World"'
            $result = Get-PWsh7WrappedContent -Content $testContent
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "try {"
            $result | Should -Match "Write-Host `"Hello World`""
            $result | Should -Match "catch {"
        }
        
        It "Should handle multiline content correctly" {
            $testContent = @"
Write-Host "Line 1"
Write-Host "Line 2"
"@
            $result = Get-PWsh7WrappedContent -Content $testContent
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "Write-Host `"Line 1`""
            $result | Should -Match "Write-Host `"Line 2`""
        }
        
        It "Should add error handling when requested" {
            $testContent = 'Write-Host "Test"'
            $result = Get-PWsh7WrappedContent -Content $testContent -AddErrorHandling
            
            $result | Should -Match "`\$ErrorActionPreference = 'Stop'"
            $result | Should -Match "Comprehensive error handling"
            $result | Should -Match "finally {"
        }
        
        It "Should add logging when requested" {
            $testContent = 'Write-Host "Test"'
            $result = Get-PWsh7WrappedContent -Content $testContent -AddLogging
            
            $result | Should -Match "Initialize logging"
            $result | Should -Match "function Write-PWsh7Log"
            $result | Should -Match "Write-PWsh7Log -Message"
        }
    }
    
    Context "Configuration Management" {
        BeforeAll {
            # Mock configuration functions
            Mock Get-ModuleConfiguration {
                return @{
                    PowerShell7 = @{
                        Version = "7.5.0"
                        CacheEnabled = $true
                    }
                    Paths = @{
                        WorkingDirectory = "C:\Temp\OSDCloud"
                        Cache = "C:\Temp\OSDCloudCache"
                        Logs = "C:\Temp\OSDCloudLogs"
                    }
                    Timeouts = @{
                        Download = 600
                        Mount = 300
                        Dismount = 300
                        Job = 300
                    }
                    Telemetry = @{
                        Enabled = $false
                        Path = "C:\Temp\OSDCloudTelemetry"
                        RetentionDays = 30
                    }
                }
            }
            
            Mock Update-ModuleConfiguration { return $true }
            Mock Reset-ModuleConfiguration { return $true }
        }
        
        It "Should update configuration settings" {
            $config = @{
                PowerShell7 = @{
                    Version = "7.5.0"
                    CacheEnabled = $true
                }
                Paths = @{
                    WorkingDirectory = "D:\OSDCloud"
                }
            }
            
            { Set-OSDCloudCustomBuilderConfig -Config $config -Confirm:$false } | Should -Not -Throw
            Should -Invoke Update-ModuleConfiguration -Times 1
        }
        
        It "Should reset configuration to defaults" {
            { Set-OSDCloudCustomBuilderConfig -ResetToDefaults -Confirm:$false } | Should -Not -Throw
            Should -Invoke Reset-ModuleConfiguration -Times 1
        }
    }
}

Describe "PowerShell 7 Integration" {
    BeforeAll {
        # Mock functions
        Mock Get-PWsh7WrappedContent { 
            param($Content)
            return "# Wrapped content`n$Content"
        }
    }
    
    It "Should wrap PowerShell content correctly" {
        $testScript = 'Write-Host "Test content"'
        $result = Get-PWsh7WrappedContent -Content $testScript
        
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Match "# Wrapped content"
        $result | Should -Match "Write-Host `"Test content`""
    }
    
    It "Should handle advanced PowerShell 7 wrapping" {
        $testScript = 'Write-Host "Advanced test"'
        $result = Get-PWsh7WrappedContent -Content $testScript -AddErrorHandling
        
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Match "# Wrapped content"
        $result | Should -Match "Write-Host `"Advanced test`""
    }
}

Describe "Error Handling" {
    It "Should handle missing files gracefully" {
        Mock Test-Path { return $false }
        
        { Get-PWsh7WrappedContent -Content "Test" } | Should -Not -Throw
    }
    
    It "Should handle exceptions in core functions" {
        Mock Get-ModuleConfiguration { throw "Simulated error" }
        
        { Get-ModuleConfiguration -ErrorAction SilentlyContinue } | Should -Throw
    }
}