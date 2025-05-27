# Import the module before testing
Import-Module (Join-Path $PSScriptRoot '..\OSDCloudCustomBuilder.psd1') -Force

# Import test helper modules
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Admin-MockHelper.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Interactive-MockHelper.psm1') -Force

BeforeAll {
    # Set up admin context mock
    Set-TestAdminContext -IsAdmin $true

    # Initialize the logger
    Initialize-TestLogger
}

Describe "Add-OSDCloudCustomDriver Tests" {
    BeforeEach {
        # Set up mocked parameters
        Set-MockedParameter -CommandName 'Add-OSDCloudCustomDriver' -Parameters @{
            DriverPath = 'C:\TestDrivers'
        }

        # Mock file system
        Mock-FileSystem -MockedDirectories @('C:\TestDrivers')
    }

    It "Should run Add-OSDCloudCustomDriver without error" {
        { Add-OSDCloudCustomDriver -DriverPath 'C:\TestDrivers' } | Should -Not -Throw
    }

    It "Should throw on invalid input (if applicable)" {
        { Add-OSDCloudCustomDriver -Path $null } | Should -Throw
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
