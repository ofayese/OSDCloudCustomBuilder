# File: Tests/Update-CustomWimWithPwsh7.Tests.ps1
Set-StrictMode -Version Latest

Describe "Update-CustomWimWithPwsh7 Function Tests" {
    BeforeAll {
        # Import the module for testing
        $modulePath = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -Name $modulePath -Force
        
        # Mock Write-OSDCloudLog to avoid errors
        function Write-OSDCloudLog {
            param($Message, $Level, $Component, $Exception)
            # Do nothing for tests
        }
        
        # Create test directories and files
        $testRoot = Join-Path -Path $TestDrive -ChildPath "UpdateWimTest"
        $testWim = Join-Path -Path $testRoot -ChildPath "test.wim"
        $testOutput = Join-Path -Path $testRoot -ChildPath "Output"
        $testTemp = Join-Path -Path $testRoot -ChildPath "Temp"
        $testWorkspace = Join-Path -Path $testTemp -ChildPath "Workspace"
        
        # Create directories
        New-Item -Path $testRoot -ItemType Directory -Force
        New-Item -Path $testOutput -ItemType Directory -Force
        New-Item -Path $testTemp -ItemType Directory -Force
        New-Item -Path $testWorkspace -ItemType Directory -Force
        
        # Create dummy WIM file
        "DUMMY WIM CONTENT" | Out-File -FilePath $testWim -Force
        
        # Mock common functions
        Mock Test-IsAdmin { return $true }
        Mock Test-Path { return $true }
        Mock Get-PSDrive {
            [PSCustomObject]@{
                Name = "C"
                Free = 50GB
            }
        }
        
        # Mock module configuration
        Mock Get-ModuleConfiguration {
            return @{
                PowerShell7 = @{
                    Version = "7.5.0"
                    CacheEnabled = $true
                }
                Paths = @{
                    WorkingDirectory = $testTemp
                    CachePath = Join-Path -Path $testTemp -ChildPath "Cache"
                }
                Timeouts = @{
                    Download = 600
                    Mount = 300
                    Dismount = 300
                    Job = 300
                }
                Telemetry = @{
                    Enabled = $false
                }
            }
        }
        
        # Mock specific functions used by Update-CustomWimWithPwsh7
        Mock Get-CachedPowerShellPackage { return Join-Path -Path $testTemp -ChildPath "PowerShell-7.5.0-win-x64.zip" }
        Mock Get-PowerShell7Package { return Join-Path -Path $testTemp -ChildPath "PowerShell-7.5.0-win-x64.zip" }
        Mock Copy-CustomWimToWorkspace { return $true }
        Mock New-Item { return $true }
        Mock Start-ThreadJob {
            return [PSCustomObject]@{
                Id = 1
                State = "Completed"
            }
        }
        Mock Start-Job {
            return [PSCustomObject]@{
                Id = 2
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
        Mock New-CustomISO { return $true }
        Mock Show-Summary { return $true }
        Mock Remove-Item { return $true }
    }
    
    Context "Parameter Validation" {
        It "Should require WimPath parameter" {
            { Update-CustomWimWithPwsh7 -OutputPath $testOutput -Confirm:$false } | 
                Should -Throw -ExpectedMessage "*The WimPath*"
        }
        
        It "Should require OutputPath parameter" {
            { Update-CustomWimWithPwsh7 -WimPath $testWim -Confirm:$false } | 
                Should -Throw -ExpectedMessage "*The OutputPath*"
        }
        
        It "Should validate PowerShell version format" {
            { Update-CustomWimWithPwsh7 -WimPath $testWim -OutputPath $testOutput -PowerShellVersion "invalid" -Confirm:$false } | 
                Should -Throw -ExpectedMessage "*Invalid PowerShell version*"
        }
    }
    
    Context "Basic Functionality" {
        It "Should run successfully with minimal parameters" {
            # Mock Test-ValidPowerShellVersion to always return true for testing
            Mock Test-ValidPowerShellVersion { return $true }
            
            { Update-CustomWimWithPwsh7 -WimPath $testWim -OutputPath $testOutput -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke Get-ModuleConfiguration -Times 1
            Should -Invoke Get-CachedPowerShellPackage -Times 1
            Should -Invoke Copy-CustomWimToWorkspace -Times 1
            Should -Invoke Start-ThreadJob -Times 2 -Exactly
            Should -Invoke Wait-Job -Times 1
            Should -Invoke Receive-Job -Times 2
            Should -Invoke New-CustomISO -Times 1
            Should -Invoke Show-Summary -Times 1
        }
        
        It "Should use cached PowerShell 7 package when available" {
            # Mock Test-ValidPowerShellVersion to always return true for testing
            Mock Test-ValidPowerShellVersion { return $true }
            Mock Get-CachedPowerShellPackage { return Join-Path -Path $testTemp -ChildPath "PowerShell-7.5.0-win-x64.zip" }
            
            { Update-CustomWimWithPwsh7 -WimPath $testWim -OutputPath $testOutput -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke Get-CachedPowerShellPackage -Times 1
            Should -Invoke Get-PowerShell7Package -Times 0
        }
        
        It "Should download PowerShell 7 package when not cached" {
            # Mock Test-ValidPowerShellVersion to always return true for testing
            Mock Test-ValidPowerShellVersion { return $true }
            Mock Get-CachedPowerShellPackage { return $null }
            Mock Get-PowerShell7Package { return Join-Path -Path $testTemp -ChildPath "PowerShell-7.5.0-win-x64.zip" }
            
            { Update-CustomWimWithPwsh7 -WimPath $testWim -OutputPath $testOutput -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke Get-CachedPowerShellPackage -Times 1
            Should -Invoke Get-PowerShell7Package -Times 1
        }
    }
    
    Context "Error Handling" {
        It "Should handle background job failures" {
            # Mock Test-ValidPowerShellVersion to always return true for testing
            Mock Test-ValidPowerShellVersion { return $true }
            Mock Receive-Job {
                return @{
                    Success = $false
                    Message = "Operation failed"
                }
            }
            
            { Update-CustomWimWithPwsh7 -WimPath $testWim -OutputPath $testOutput -Confirm:$false -ErrorAction SilentlyContinue } | 
                Should -Throw -ExpectedMessage "*One or more background tasks failed*"
        }
        
        It "Should handle ISO creation failures" {
            # Mock Test-ValidPowerShellVersion to always return true for testing
            Mock Test-ValidPowerShellVersion { return $true }
            Mock New-CustomISO { throw "ISO creation failed" }
            
            { Update-CustomWimWithPwsh7 -WimPath $testWim -OutputPath $testOutput -Confirm:$false -ErrorAction SilentlyContinue } | 
                Should -Throw -ExpectedMessage "*ISO creation failed*"
        }
    }
    
    Context "Cleanup Behavior" {
        It "Should clean up temporary files by default" {
            # Mock Test-ValidPowerShellVersion to always return true for testing
            Mock Test-ValidPowerShellVersion { return $true }
            
            { Update-CustomWimWithPwsh7 -WimPath $testWim -OutputPath $testOutput -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke Remove-Item -Times 1
        }
        
        It "Should skip cleanup when SkipCleanup is specified" {
            # Mock Test-ValidPowerShellVersion to always return true for testing
            Mock Test-ValidPowerShellVersion { return $true }
            
            { Update-CustomWimWithPwsh7 -WimPath $testWim -OutputPath $testOutput -SkipCleanup -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke Remove-Item -Times 0
        }
    }
    
    Context "ThreadJob Support" {
        It "Should use ThreadJob when available" {
            # Mock Test-ValidPowerShellVersion to always return true for testing
            Mock Test-ValidPowerShellVersion { return $true }
            Mock Get-Command { return $true } -ParameterFilter { $Name -eq 'Start-ThreadJob' }
            
            { Update-CustomWimWithPwsh7 -WimPath $testWim -OutputPath $testOutput -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke Start-ThreadJob -Times 2
            Should -Invoke Start-Job -Times 0
        }
        
        It "Should fall back to standard Jobs when ThreadJob is not available" {
            # Mock Test-ValidPowerShellVersion to always return true for testing
            Mock Test-ValidPowerShellVersion { return $true }
            Mock Get-Command { return $false } -ParameterFilter { $Name -eq 'Start-ThreadJob' }
            Mock Get-Module { return $null } -ParameterFilter { $Name -eq 'ThreadJob' }
            
            { Update-CustomWimWithPwsh7 -WimPath $testWim -OutputPath $testOutput -Confirm:$false } | 
                Should -Not -Throw
            
            Should -Invoke Start-ThreadJob -Times 0
            Should -Invoke Start-Job -Times 2
        }
    }
}