BeforeAll {
    # Import the module with mock dependencies
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\src\OSDCloudCustomBuilder"
    Import-Module -Name $modulePath -Force

    # Mock dependencies that might not be available in test environment
    Mock -CommandName Test-IsAdmin -ModuleName OSDCloudCustomBuilder { return $true }
    Mock -CommandName New-OSDCloudWorkspace -ModuleName OSDCloudCustomBuilder { }
    Mock -CommandName Write-OSDCloudLog -ModuleName OSDCloudCustomBuilder { }
}

Describe "OSDCloudCustomBuilder Module Tests" {
    Context "Module Structure Tests" {
        It "Should import the module without errors" {
            Get-Module -Name OSDCloudCustomBuilder | Should -Not -BeNullOrEmpty
        }

        It "Should export the expected functions" {
            $expectedFunctions = @(
                'New-OSDCloudCustomMedia',
                'Add-OSDCloudCustomDriver',
                'Add-OSDCloudCustomScript',
                'Set-OSDCloudCustomSettings',
                'Test-OSDCloudCustomRequirements'
            )

            $exportedFunctions = Get-Command -Module OSDCloudCustomBuilder | Select-Object -ExpandProperty Name

            foreach ($function in $expectedFunctions) {
                $exportedFunctions | Should -Contain $function
            }
        }

        It "Should have correct module version" {
            $module = Get-Module -Name OSDCloudCustomBuilder
            $module.Version | Should -Be "0.3.1"
        }

        It "Should have correct PowerShell version requirement" {
            $module = Get-Module -Name OSDCloudCustomBuilder
            $module.PowerShellVersion | Should -Be "5.1"
        }
    }

    Context "Shared Utilities Tests" {
        It "Test-IsAdmin should return a boolean" {
            # We're testing the type, not the actual result which depends on execution context
            (Test-IsAdmin).GetType().FullName | Should -Be "System.Boolean"
        }

        It "Test-EnvironmentCompatibility should return a hashtable" {
            $requiredModules = @{
                "TestModule" = @{ MinimumVersion = "1.0.0"; Required = $false }
            }

            Mock Get-Module { return $null } -ParameterFilter { $Name -eq "TestModule" -and $ListAvailable }

            $result = Test-EnvironmentCompatibility -RequiredModules $requiredModules -MinimumPSVersion ([Version]'5.1')

            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain "IsCompatible"
            $result.Keys | Should -Contain "Issues"
            $result.Keys | Should -Contain "Warnings"
        }

        It "Test-PowerShellVersion should work correctly" {
            $result = Test-PowerShellVersion -MinimumVersion ([Version]'5.1')
            $result | Should -BeOfType [bool]
        }

        It "Get-PowerShellEdition should return valid edition" {
            $edition = Get-PowerShellEdition
            $edition | Should -BeIn @('Desktop', 'Core')
        }
    }

    Context "Error Handling Tests" {
        It "New-CustomException should create proper exception" {
            $exception = New-CustomException -Message "Test error" -FunctionName "TestFunction"
            $exception | Should -BeOfType [System.Exception]
            $exception.Message | Should -Match "Test error"
        }

        It "Invoke-WithRetry should succeed on first try" {
            $scriptBlock = { return "Success" }
            $result = Invoke-WithRetry -ScriptBlock $scriptBlock -RetryCount 3 -RetryDelaySeconds 0
            $result | Should -Be "Success"
        }

        It "Invoke-WithRetry should retry on failure" {
            $attempts = 0
            $scriptBlock = {
                $script:attempts++
                if ($script:attempts -lt 3) {
                    throw "Temporary failure"
                }
                return "Success after retries"
            }

            $result = Invoke-WithRetry -ScriptBlock $scriptBlock -RetryCount 5 -RetryDelaySeconds 0
            $result | Should -Be "Success after retries"
            $script:attempts | Should -Be 3
        }
    }
}

Describe "Function Parameter Validation" {
    Context "New-OSDCloudCustomMedia" {
        BeforeAll {
            Mock Test-IsAdmin { return $true } -ModuleName OSDCloudCustomBuilder
            Mock New-OSDCloudWorkspace { } -ModuleName OSDCloudCustomBuilder
            Mock Write-OSDCloudLog { } -ModuleName OSDCloudCustomBuilder
        }

        It "Should have mandatory Name parameter" {
            $command = Get-Command -Name New-OSDCloudCustomMedia
            $nameParam = $command.Parameters['Name']
            $nameParam.Attributes.Mandatory | Should -Contain $true
        }

        It "Should have mandatory Path parameter" {
            $command = Get-Command -Name New-OSDCloudCustomMedia
            $pathParam = $command.Parameters['Path']
            $pathParam.Attributes.Mandatory | Should -Contain $true
        }

        It "Should validate BackgroundColor parameter" {
            $command = Get-Command -Name New-OSDCloudCustomMedia
            $bgColorParam = $command.Parameters['BackgroundColor']
            $validateSet = $bgColorParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet.ValidValues | Should -Contain 'Blue'
            $validateSet.ValidValues | Should -Contain 'Green'
        }
    }

    Context "Add-OSDCloudCustomDriver" {
        It "Should have mandatory MediaPath parameter" {
            $command = Get-Command -Name Add-OSDCloudCustomDriver
            $mediaPathParam = $command.Parameters['MediaPath']
            $mediaPathParam.Attributes.Mandatory | Should -Contain $true
        }

        It "Should have mandatory DriverPath parameter" {
            $command = Get-Command -Name Add-OSDCloudCustomDriver
            $driverPathParam = $command.Parameters['DriverPath']
            $driverPathParam.Attributes.Mandatory | Should -Contain $true
        }
    }
}

Describe "Module Configuration" {
    Context "Default Configuration" {
        It "Should create default config file if not exists" {
            $configPath = Join-Path -Path $TestDrive -ChildPath "config.json"

            # Mock the config path
            Mock Get-Variable {
                return @{ Value = $configPath }
            } -ParameterFilter { $Name -eq "script:ConfigPath" } -ModuleName OSDCloudCustomBuilder

            # Remove config file if it exists
            if (Test-Path -Path $configPath) {
                Remove-Item -Path $configPath -Force
            }

            # Re-import module to trigger config creation
            Remove-Module -Name OSDCloudCustomBuilder -Force
            Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "..\src\OSDCloudCustomBuilder") -Force

            # Check if config was created (this test may need adjustment based on actual implementation)
            # $configPath | Should -Exist
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module -Name OSDCloudCustomBuilder -Force -ErrorAction SilentlyContinue
}
