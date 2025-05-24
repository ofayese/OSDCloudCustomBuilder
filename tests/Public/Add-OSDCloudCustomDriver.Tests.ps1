BeforeAll {
    # Import module and dependencies
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\src\OSDCloudCustomBuilder"
    Import-Module -Name $modulePath -Force

    # Create test paths
    $testRoot = Join-Path -Path $TestDrive -ChildPath "TestDrivers"
    $testDriverPath = Join-Path -Path $testRoot -ChildPath "TestDriver"
    $testInfPath = Join-Path -Path $testDriverPath -ChildPath "test.inf"

    # Create test driver structure
    New-Item -Path $testDriverPath -ItemType Directory -Force | Out-Null
    Set-Content -Path $testInfPath -Value "[Version]`nSignature=`"$Windows NT$`""
}

Describe "Add-OSDCloudCustomDriver" {
    BeforeEach {
        # Mock common functions
        Mock Get-OSDCloudConfig {
            @{
                TempWorkspacePath = Join-Path -Path $TestDrive -ChildPath "Workspace"
            }
        }
        Mock Get-WindowsDriver {
            @(
                @{
                    Driver = "Test Driver"
                    ClassDescription = "Test Class"
                    OriginalFileName = $testInfPath
                    ProviderName = "Test Provider"
                    Date = (Get-Date)
                }
            )
        }
        Mock Invoke-OSDCloudLogger { }
        Mock Write-Error { }
        Mock Write-Warning { }
        Mock Write-Verbose { }
    }

    Context "Parameter Validation" {
        It "Should accept valid driver path" {
            { Add-OSDCloudCustomDriver -DriverPath $testDriverPath -WhatIf } | Should -Not -Throw
        }

        It "Should throw on invalid driver path" {
            { Add-OSDCloudCustomDriver -DriverPath "NonExistentPath" } | Should -Throw
        }

        It "Should accept all valid catalog levels" {
            @('Basic', 'Standard', 'Advanced') | ForEach-Object {
                { Add-OSDCloudCustomDriver -DriverPath $testDriverPath -CatalogLevel $_ -WhatIf } | Should -Not -Throw
            }
        }

        It "Should require administrator privileges" {
            Mock ([Security.Principal.WindowsPrincipal]) {
                return [PSCustomObject]@{ IsInRole = { return $false } }
            }
            { Add-OSDCloudCustomDriver -DriverPath $testDriverPath } | Should -Throw "*Administrator privileges*"
        }
    }

    Context "Driver Processing" {
        BeforeEach {
            $workspace = Join-Path -Path $TestDrive -ChildPath "Workspace\Drivers"
            New-Item -Path $workspace -ItemType Directory -Force | Out-Null
        }

        It "Should create driver catalog with correct level" {
            Add-OSDCloudCustomDriver -DriverPath $testDriverPath -CatalogLevel Advanced -Force
            $catalogPath = Join-Path -Path $workspace -ChildPath (Split-Path -Leaf $testDriverPath) "catalog.csv"
            Should -Exist $catalogPath
            $catalogContent = Import-Csv -Path $catalogPath
            $catalogContent | Should -Not -BeNullOrEmpty
        }

        It "Should handle Force parameter correctly" {
            # First addition should work
            Add-OSDCloudCustomDriver -DriverPath $testDriverPath -Force
            Should -Invoke Write-Warning -Times 0

            # Second addition without Force should warn
            Add-OSDCloudCustomDriver -DriverPath $testDriverPath
            Should -Invoke Write-Warning -Times 1

            # Second addition with Force should not warn
            Add-OSDCloudCustomDriver -DriverPath $testDriverPath -Force
            Should -Invoke Write-Warning -Times 1
        }

        It "Should properly validate driver content" {
            Remove-Item -Path $testInfPath -Force
            { Add-OSDCloudCustomDriver -DriverPath $testDriverPath } | Should -Throw "*No driver (.inf) files found*"
        }
    }

    Context "Logging" {
        It "Should log operations when logger is available" {
            Add-OSDCloudCustomDriver -DriverPath $testDriverPath -Force
            Should -Invoke Invoke-OSDCloudLogger -Times 3 # Start, Success, and End messages
        }

        It "Should use Write-Verbose when logger is not available" {
            Mock Get-Command { return $false }
            Add-OSDCloudCustomDriver -DriverPath $testDriverPath -Force
            Should -Invoke Write-Verbose -Times 1
        }
    }
}

Describe "Add-OSDCloudCustomDriver Integration" -Tags "Integration" {
    BeforeAll {
        # Setup real test environment
        $integrationRoot = Join-Path -Path $TestDrive -ChildPath "Integration"
        $realDriverPath = Join-Path -Path $integrationRoot -ChildPath "RealDrivers"
        New-Item -Path $realDriverPath -ItemType Directory -Force | Out-Null

        # Create a simple test driver
        $infContent = @"
[Version]
Signature="$Windows NT$"
Class=System
ClassGuid={4D36E97D-E325-11CE-BFC1-08002BE10318}
Provider=%Provider%
DriverVer=05/23/2025,1.0.0.0
CatalogFile=test.cat

[SourceDisksNames]
1 = %DiskName%,,,""

[SourceDisksFiles]
test.sys = 1

[Manufacturer]
%ManufacturerName%=Standard,NTamd64

[Standard.NTamd64]
%DeviceName%=Install,ROOT\TEST

[Strings]
Provider = "Test Provider"
ManufacturerName = "Test Manufacturer"
DiskName = "Test Installation Disk"
DeviceName = "Test Device"
"@
        Set-Content -Path (Join-Path -Path $realDriverPath -ChildPath "test.inf") -Value $infContent
    }

    It "Should process real driver files" {
        { Add-OSDCloudCustomDriver -DriverPath $realDriverPath -CatalogLevel Advanced } | Should -Not -Throw
        $catalogPath = Join-Path -Path $realDriverPath -ChildPath "catalog.csv"
        $catalog = Import-Csv -Path $catalogPath
        $catalog | Should -Not -BeNullOrEmpty
        $catalog.Count | Should -BeGreaterThan 0
    }
}
