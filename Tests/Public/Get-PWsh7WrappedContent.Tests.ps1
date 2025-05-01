# File: Tests/Public/Get-PWsh7WrappedContent.Tests.ps1
Set-StrictMode -Version Latest

Describe "Get-PWsh7WrappedContent Function Tests" {
    BeforeAll {
        # Import the function we're testing
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
        $moduleRoot = Split-Path -Parent (Split-Path -Parent $here)
        . "$moduleRoot/Public/Get-PWsh7WrappedContent.ps1"
        
        # Mock Write-OSDCloudLog to avoid errors
        function Write-OSDCloudLog {
            param($Message, $Level, $Component, $Exception)
            # Do nothing for tests
        }
        
        # Mock Get-ModuleConfiguration
        function Get-ModuleConfiguration {
            return @{
                PowerShell7 = @{
                    Logging = @{
                        DefaultPath = "X:\OSDCloud\CustomLogs"
                        IncludeTimestamp = $true
                        DefaultLevel = "Debug"
                    }
                }
            }
        }
    }
    
    Context "Basic functionality" {
        It "Should return a string with wrapped content" {
            $testContent = 'Write-Host "Test"'
            $result = Get-PWsh7WrappedContent -Content $testContent
            
            $result | Should -BeOfType [string]
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should include the original content in the wrapped result" {
            $testContent = 'Write-Host "Hello World"'
            $result = Get-PWsh7WrappedContent -Content $testContent
            
            $result | Should -Match ([regex]::Escape('Write-Host "Hello World"'))
        }
        
        It "Should wrap the content in a try/catch block" {
            $testContent = 'Write-Host "Test"'
            $result = Get-PWsh7WrappedContent -Content $testContent
            
            $result | Should -Match "try \{"
            $result | Should -Match "catch \{"
        }
    }
    
    Context "Error handling" {
        It "Should add comprehensive error handling when requested" {
            $testContent = 'Write-Host "Test"'
            $result = Get-PWsh7WrappedContent -Content $testContent -AddErrorHandling
            
            $result | Should -Match "\`\$ErrorActionPreference = 'Stop'"
            $result | Should -Match "\`\$errorRecord = \`\$_"
            $result | Should -Match "\`\$errorMessage"
            $result | Should -Match "\`\$errorLine"
            $result | Should -Match "\`\$errorType"
            $result | Should -Match "finally \{"
            $result | Should -Match "\[System\.GC\]::Collect\(\)"
        }
    }
    
    Context "Logging" {
        It "Should add logging functionality when requested" {
            $testContent = 'Write-Host "Test"'
            $result = Get-PWsh7WrappedContent -Content $testContent -AddLogging
            
            $result | Should -Match "function Write-PWsh7Log"
            $result | Should -Match "Write-PWsh7Log -Message"
            $result | Should -Match "\`\$logFilePath"
            $result | Should -Match "New-Item -Path \`\$logDirectory"
        }
        
        It "Should use custom log path when provided" {
            $testContent = 'Write-Host "Test"'
            $customLogPath = "D:\CustomLogs"
            $result = Get-PWsh7WrappedContent -Content $testContent -AddLogging -LogPath $customLogPath
            
            $result | Should -Match ([regex]::Escape($customLogPath))
        }
        
        It "Should handle log level configuration" {
            $testContent = 'Write-Host "Test"'
            $result = Get-PWsh7WrappedContent -Content $testContent -AddLogging -LogLevel "Debug"
            
            $result | Should -Match "\`\$minimumLogLevel = `"DEBUG`""
        }
    }
    
    Context "Edge cases" {
        It "Should handle null content" {
            $result = Get-PWsh7WrappedContent -Content $null
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "try \{"
            $result | Should -Match "catch \{"
            $result | Should -Match "# Empty script content provided"
        }
        
        It "Should handle empty string content" {
            $result = Get-PWsh7WrappedContent -Content ""
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "try \{"
            $result | Should -Match "catch \{"
            $result | Should -Match "# Empty script content provided"
        }
        
        It "Should handle multiline content" {
            $testContent = @"
Write-Host "Line 1"
Write-Host "Line 2"
Write-Host "Line 3"
"@
            $result = Get-PWsh7WrappedContent -Content $testContent
            
            $result | Should -Match ([regex]::Escape('Write-Host "Line 1"'))
            $result | Should -Match ([regex]::Escape('Write-Host "Line 2"'))
            $result | Should -Match ([regex]::Escape('Write-Host "Line 3"'))
        }
        
        It "Should handle content with special characters" {
            $testContent = 'Write-Host "Test with $special `characters"'
            $result = Get-PWsh7WrappedContent -Content $testContent
            
            $result | Should -Match ([regex]::Escape('Write-Host "Test with $special `characters"'))
        }
    }
    
    Context "Combined features" {
        It "Should combine error handling and logging when both are requested" {
            $testContent = 'Write-Host "Test"'
            $result = Get-PWsh7WrappedContent -Content $testContent -AddErrorHandling -AddLogging
            
            $result | Should -Match "function Write-PWsh7Log"
            $result | Should -Match "\`\$ErrorActionPreference = 'Stop'"
            $result | Should -Match "Write-PWsh7Log -Message"
            $result | Should -Match "\`\$errorRecord = \`\$_"
            $result | Should -Match "finally \{"
        }
        
        It "Should use timestamp format based on IncludeTimestamp parameter" {
            $testContent = 'Write-Host "Test"'
            $result = Get-PWsh7WrappedContent -Content $testContent -AddLogging -IncludeTimestamp
            
            $result | Should -Match "fff" # Milliseconds format
        }
    }
}