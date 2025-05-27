# Import the module before testing
Import-Module (Join-Path $PSScriptRoot '..\OSDCloudCustomBuilder.psd1') -Force -ErrorAction Stop

# Import test helper modules
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Admin-MockHelper.psm1') -Force -ErrorAction Stop
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Interactive-MockHelper.psm1') -Force -ErrorAction Stop

BeforeAll {
    # Set up admin context mock - ensure this happens first
    Set-TestAdminContext -IsAdmin $true

    # Initialize the logger with proper setup
    Initialize-TestLogger

    # Explicitly make Test-IsAdmin mock available in the OSDCloudCustomBuilder module
    Mock -CommandName Test-IsAdmin -ModuleName OSDCloudCustomBuilder -MockWith {
        return $true
    } -Verifiable

    # Also make it available in the global scope
    Mock -CommandName Test-IsAdmin -MockWith {
        return $true
    } -Verifiable

    # Setup shared mock file system paths for tests
    try {
        # Define a function to initialize mock filesystem directly in this scope
        function Initialize-FileSystemMocks {
            [CmdletBinding()]
            param(
                [string[]]$MockedDirectories = @(),
                [hashtable]$MockedFiles = @{}
            )

            # Create mocks for each directory
            foreach ($dir in $MockedDirectories) {
                Mock -CommandName Test-Path -ParameterFilter { $Path -eq $dir } -MockWith { return $true }
            }

            # Create mocks for each file
            foreach ($file in $MockedFiles.Keys) {
                Mock -CommandName Test-Path -ParameterFilter { $Path -eq $file } -MockWith { return $true }
                Mock -CommandName Get-Content -ParameterFilter { $Path -eq $file } -MockWith { return $MockedFiles[$file] }
            }
        }

        Initialize-FileSystemMocks -MockedDirectories @(
            'C:\TestDrivers',
            'C:\TestScripts',
            'C:\TestMedia',
            'C:\TestWim'
        ) -MockedFiles @{
            'C:\TestWim\boot.wim'       = 'WIM Content'
            'C:\TestScripts\script.ps1' = 'Script Content'
        }
    } catch {
        Write-Warning "Failed to initialize file system mocks: $_"
    }

    # Common mocks needed across tests
    Mock -CommandName Invoke-OSDCloudLogger -ModuleName OSDCloudCustomBuilder

    # Mock path validation function
    Mock -CommandName Test-ValidPath -ModuleName OSDCloudCustomBuilder -MockWith {
        param($Path)
        # Return true for any non-empty path
        return -not [string]::IsNullOrWhiteSpace($Path)
    }

    # Mock other common functions that may be called across tests
    Mock -CommandName Initialize-OSDEnvironment -ModuleName OSDCloudCustomBuilder -MockWith {
        # Return success
        return $true
    }
}

Describe "Add-OSDCloudCustomDriver Tests" {
    BeforeEach {
        # Set up mocked parameters
        Set-MockedParameter -CommandName 'Add-OSDCloudCustomDriver' -Parameters @{
            DriverPath = 'C:\TestDrivers'
        }

        # Mock any specific functions called by Add-OSDCloudCustomDriver
        Mock -CommandName Test-Path -ModuleName OSDCloudCustomBuilder -MockWith {
            param($Path)
            return $Path -eq 'C:\TestDrivers'
        }

        # Mock Copy-Item for driver files
        Mock -CommandName Copy-Item -ModuleName OSDCloudCustomBuilder -MockWith {
            # Return success
            return $true
        }
    }

    It "Should run Add-OSDCloudCustomDriver without error" {
        { Add-OSDCloudCustomDriver -DriverPath 'C:\TestDrivers' } | Should -Not -Throw
        Should -Invoke -CommandName Test-Path -ModuleName OSDCloudCustomBuilder -Times 1
    }

    It "Should throw on invalid input" {
        { Add-OSDCloudCustomDriver -DriverPath '' } | Should -Throw
    }
}


Describe "Add-OSDCloudCustomScript Tests" {
    It "Should run Add-OSDCloudCustomScript without error" {
        { Add-OSDCloudCustomScript } | Should -Not -Throw
    }

    It "Should throw on invalid input (if applicable)" {
        { Add-OSDCloudCustomScript -Path $null } | Should -Throw
    }
}


Describe "Enable-OSDCloudTelemetry Tests" {
    It "Should run Enable-OSDCloudTelemetry without error" {
        { Enable-OSDCloudTelemetry } | Should -Not -Throw
    }

    It "Should throw on invalid input (if applicable)" {
        { Enable-OSDCloudTelemetry -Path $null } | Should -Throw
    }
}


Describe "Get-PWsh7WrappedContent Tests" {
    It "Should run Get-PWsh7WrappedContent without error" {
        { Get-PWsh7WrappedContent } | Should -Not -Throw
    }

    It "Should throw on invalid input (if applicable)" {
        { Get-PWsh7WrappedContent -Path $null } | Should -Throw
    }
}


Describe "New-CustomOSDCloudISO Tests" {
    It "Should run New-CustomOSDCloudISO without error" {
        { New-CustomOSDCloudISO } | Should -Not -Throw
    }

    It "Should throw on invalid input (if applicable)" {
        { New-CustomOSDCloudISO -Path $null } | Should -Throw
    }
}


Describe "New-OSDCloudCustomMedia Tests" {
    It "Should run New-OSDCloudCustomMedia without error" {
        { New-OSDCloudCustomMedia } | Should -Not -Throw
    }

    It "Should throw on invalid input (if applicable)" {
        { New-OSDCloudCustomMedia -Path $null } | Should -Throw
    }
}


Describe "Set-OSDCloudCustomSettings Tests" {
    It "Should run Set-OSDCloudCustomSettings without error" {
        { Set-OSDCloudCustomSettings } | Should -Not -Throw
    }

    It "Should throw on invalid input (if applicable)" {
        { Set-OSDCloudCustomSettings -Path $null } | Should -Throw
    }
}


Describe "Set-OSDCloudTelemetry Tests" {
    It "Should run Set-OSDCloudTelemetry without error" {
        { Set-OSDCloudTelemetry } | Should -Not -Throw
    }

    It "Should throw on invalid input (if applicable)" {
        { Set-OSDCloudTelemetry -Path $null } | Should -Throw
    }
}


Describe "Test-OSDCloudCustomRequirements Tests" {
    It "Should run Test-OSDCloudCustomRequirements without error" {
        { Test-OSDCloudCustomRequirements } | Should -Not -Throw
    }

    It "Should throw on invalid input (if applicable)" {
        { Test-OSDCloudCustomRequirements -Path $null } | Should -Throw
    }
}


Describe "Update-CustomWimWithPwsh7 Tests" {
    It "Should run Update-CustomWimWithPwsh7 without error" {
        { Update-CustomWimWithPwsh7 } | Should -Not -Throw
    }

    It "Should throw on invalid input (if applicable)" {
        { Update-CustomWimWithPwsh7 -Path $null } | Should -Throw
    }
}


Describe "Update-CustomWimWithPwsh7Advanced Tests" {
    It "Should run Update-CustomWimWithPwsh7Advanced without error" {
        { Update-CustomWimWithPwsh7Advanced } | Should -Not -Throw
    }

    It "Should throw on invalid input (if applicable)" {
        { Update-CustomWimWithPwsh7Advanced -Path $null } | Should -Throw
    }
}
