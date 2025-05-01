# File: Tests/OSDCloudCustomBuilder.Tests.ps1
Set-StrictMode -Version Latest

Describe "OSDCloudCustomBuilder Module Tests" {
    BeforeAll {
        # Import the module for testing
        $modulePath = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -Name $modulePath -Force
        
        # Define mocks for external commands if needed
        function Mount-WindowsImage { return $true }
        function Dismount-WindowsImage { return $true }
        function Get-WindowsImage { 
            return [PSCustomObject]@{
                ImageName = "Windows 10 Enterprise"
                ImageDescription = "Windows 10 Enterprise"
                ImageSize = 4GB
            }
        }
        
        # Mock functions that interact with the filesystem or external resources
        Mock Test-Path { $true }
        Mock Test-WimFileAccessible { $true }
        Mock New-Item { $true }
        
        # Mock Write-OSDCloudLog to avoid errors
        function Write-OSDCloudLog {
            param($Message, $Level, $Component, $Exception)
            # Do nothing for tests
        }
        
        # Create test directories and files
        $testRoot = Join-Path -Path $TestDrive -ChildPath "OSDCloudTest"
        $testOutput = Join-Path -Path $testRoot -ChildPath "Output"
        
        # Create directories
        New-Item -Path $testRoot -ItemType Directory -Force -ErrorAction SilentlyContinue
        New-Item -Path $testOutput -ItemType Directory -Force -ErrorAction SilentlyContinue
    }
    
    AfterAll {
        # Clean up any lingering mocks or test artifacts
        Remove-Module -Name OSDCloudCustomBuilder -ErrorAction SilentlyContinue
    }
    
    Context "Module Loading" {
        It "Should import the OSDCloudCustomBuilder module without errors" {
            { Get-Module -Name OSDCloudCustomBuilder } | Should -Not -Throw
            Get-Module -Name OSDCloudCustomBuilder | Should -Not -BeNullOrEmpty
        }
        
        It "Should export the required functions" {
            $exportedFunctions = Get-Command -Module OSDCloudCustomBuilder -CommandType Function
            $exportedFunctions.Count | Should -BeGreaterThan 0
            $exportedFunctions.Name | Should -Contain 'Update-CustomWimWithPwsh7'
            $exportedFunctions.Name | Should -Contain 'New-CustomOSDCloudISO'
            $exportedFunctions.Name | Should -Contain 'Get-PWsh7WrappedContent'
            $exportedFunctions.Name | Should -Contain 'Set-OSDCloudCustomBuilderConfig'
        }
        
        It "Should have the correct aliases defined" {
            $alias = Get-Alias -Name Add-CustomWimWithPwsh7 -ErrorAction SilentlyContinue
            $alias | Should -Not -BeNullOrEmpty
            $alias.ResolvedCommand.Name | Should -Be 'Update-CustomWimWithPwsh7'
        }
        
        It "Should have the correct module version" {
            $moduleInfo = Get-Module -Name OSDCloudCustomBuilder
            $moduleInfo.Version | Should -BeGreaterOrEqual ([Version]"0.3.0")
        }
    }
    
    Context "Get-PWsh7WrappedContent Function" {
        BeforeAll {
            # Mock any dependencies specific to this context
            Mock Get-ModuleConfiguration {
                return @{
                    PowerShell7 = @{
                        ErrorHandling = @{
                            Enabled = $true
                            LogExceptions = $true
                        }
                    }
                }
            }
        }
        
        It "Should wrap content in PowerShell 7 execution block" {
            $testContent = 'Write-Host "Hello World"'
            $result = Get-PWsh7WrappedContent -Content $testContent
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "try \{"
            $result | Should -Match "Write-Host `"Hello World`""
            $result | Should -Match "catch \{"
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
            
            $result | Should -Match "try \{"
            $result | Should -Match "catch \{"
            $result | Should -Match "Write-Host `"Test`""
        }
        
        It "Should add logging when requested" {
            $testContent = 'Write-Host "Test"'
            $result = Get-PWsh7WrappedContent -Content $testContent -AddLogging
            
            $result | Should -Match "try \{"
            $result | Should -Match "catch \{"
            $result | Should -Match "Write-Host `"Test`""
        }
        
        It "Should handle empty content" {
            $result = Get-PWsh7WrappedContent -Content ""
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "try \{"
            $result | Should -Match "catch \{"
        }
        
        It "Should handle null content" {
            $result = Get-PWsh7WrappedContent -Content $null
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "try \{"
            $result | Should -Match "catch \{"
        }
    }
    
    Context "Update-CustomWimWithPwsh7 Function" {
        BeforeAll {
            # Mock additional functions specifically for this test
            Mock Get-ModuleConfiguration {
                return @{
                    Timeouts = @{
                        Job = 300
                        Download = 600
                        Mount = 300
                        Dismount = 300
                    }
                    PowerShell7 = @{
                        Version = "7.5.0"
                        CacheEnabled = $true
                    }
                    Paths = @{
                        CachePath = "C:\Temp\OSDCloudCache"
                    }
                }
            }
            
            Mock Get-CachedPowerShellPackage { return "C:\Temp\PowerShell-7.5.0-win-x64.zip" }
            Mock Copy-CustomWimToWorkspace { return $true }
            Mock New-CustomISO { return $true }
            Mock Show-Summary { return $true }
            Mock Remove-Item { return $true }
            
            # Mock Test-ValidPowerShellVersion to always return true for testing
            Mock Test-ValidPowerShellVersion { return $true }
            
            # Mock Start-ThreadJob and related functions
            Mock Start-ThreadJob {
                return [PSCustomObject]@{
                    Id = 1
                    State = "Completed"
                }
            }
            
            Mock Wait-Job { return $true }
            
            Mock Receive-Job {
                return @{
                    Success = $true
                    Message = "Operation completed successfully"
                }
            }
            
            Mock Remove-Job { return $true }
            
            # Skip actual admin check for testing
            Mock Test-IsAdmin { return $true }
        }
        
        It "Should run with minimal parameters" {
            { Update-CustomWimWithPwsh7 -WimPath "C:\Test\windows.wim" -OutputPath "C:\Output" -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke Get-ModuleConfiguration -Times 1
            Should -Invoke Get-CachedPowerShellPackage -Times 1
            Should -Invoke Copy-CustomWimToWorkspace -Times 1
        }
        
        It "Should use cached PowerShell 7 package when available" {
            { Update-CustomWimWithPwsh7 -WimPath "C:\Test\windows.wim" -OutputPath "C:\Output" -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke Get-CachedPowerShellPackage -Times 1
            Should -Invoke Get-PowerShell7Package -Times 0
        }
        
        It "Should handle cleanup correctly when SkipCleanup is specified" {
            { Update-CustomWimWithPwsh7 -WimPath "C:\Test\windows.wim" -OutputPath "C:\Output" -SkipCleanup -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke Remove-Item -Times 0
        }
        
        It "Should validate PowerShell version format" {
            Mock Test-ValidPowerShellVersion { 
                param($Version)
                return $Version -eq "7.5.0"
            }
            
            { Update-CustomWimWithPwsh7 -WimPath "C:\Test\windows.wim" -OutputPath "C:\Output" -PowerShellVersion "7.5.0" -Confirm:$false } | 
                Should -Not -Throw
                
            { Update-CustomWimWithPwsh7 -WimPath "C:\Test\windows.wim" -OutputPath "C:\Output" -PowerShellVersion "invalid" -Confirm:$false -ErrorAction SilentlyContinue } | 
                Should -Throw
        }
    }
    
    Context "New-CustomOSDCloudISO Function" {
        BeforeAll {
            # Mock additional functions specifically for this test
            Mock Initialize-OSDCloudTemplate { return "C:\Temp\OSDCloud" }
            Mock New-CustomISO { return $true }
            Mock Show-Summary { return $true }
            Mock Remove-Item { return $true }
            
            # Skip actual admin check for testing
            Mock Test-IsAdmin { return $true }
            
            # Mock Test-ValidPowerShellVersion to always return true for testing
            Mock Test-ValidPowerShellVersion { return $true }
        }
        
        It "Should run with minimal parameters" {
            { New-CustomOSDCloudISO -OutputPath "C:\Output" -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke Initialize-OSDCloudTemplate -Times 1
            Should -Invoke New-CustomISO -Times 1
        }
        
        It "Should handle custom ISO name" {
            { New-CustomOSDCloudISO -OutputPath "C:\Output" -ISOFileName "Custom.iso" -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke New-CustomISO -Times 1
        }
        
        It "Should validate PowerShell version" {
            Mock Test-ValidPowerShellVersion { 
                param($Version)
                return $Version -eq "7.5.0"
            }
            
            { New-CustomOSDCloudISO -OutputPath "C:\Output" -PwshVersion "7.5.0" -Confirm:$false } | 
                Should -Not -Throw
                
            { New-CustomOSDCloudISO -OutputPath "C:\Output" -PwshVersion "invalid" -Confirm:$false -ErrorAction SilentlyContinue } | 
                Should -Throw
        }
    }
    
    Context "Set-OSDCloudCustomBuilderConfig Function" {
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