Describe "OSDCloudCustomBuilder Module Tests" {
    BeforeAll {
        # Import the module
        $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\out\OSDCloudCustomBuilder"
        Import-Module -Name $modulePath -Force
    }

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
                'Export-OSDCloudCustomISO',
                'Test-OSDCloudCustomRequirements'
            )

            $exportedFunctions = Get-Command -Module OSDCloudCustomBuilder | Select-Object -ExpandProperty Name

            foreach ($function in $expectedFunctions) {
                $exportedFunctions | Should -Contain $function
            }
        }
    }

    Context "Shared Utilities Tests" {
        It "Test-IsAdmin should return a boolean" {
            # We're testing the type, not the actual result which depends on execution context
            (Test-IsAdmin).GetType().FullName | Should -Be "System.Boolean"
        }
    }

    # Additional tests would be added for each function
    # These are just placeholders since we don't have the full function implementations

    Context "New-OSDCloudCustomMedia Tests" {
        BeforeAll {
            # Mock dependencies
            Mock Test-IsAdmin { return $true }
            Mock New-OSDCloudWorkspace { }
            Mock Write-LogMessage { }
        }

        It "Should throw when not run as admin" {
            Mock Test-IsAdmin { return $false }
            { New-OSDCloudCustomMedia -Name "Test" -Path "TestPath" } | Should -Throw
        }

        It "Should call New-OSDCloudWorkspace" {
            Mock Test-IsAdmin { return $true }
            New-OSDCloudCustomMedia -Name "Test" -Path "TestPath"
            Should -Invoke -CommandName New-OSDCloudWorkspace -Times 1
        }
    }
}
