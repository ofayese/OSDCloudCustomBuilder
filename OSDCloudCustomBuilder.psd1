# Module manifest for OSDCloudCustomBuilder
@{
    RootModule           = 'OSDCloudCustomBuilder.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = '69bae5f0-45c0-4003-b0a3-fcf89f8dd6df'
    Author               = 'Modern Endpoint Management'
    CompanyName          = 'Modern Endpoint Management'
    Copyright            = '(c) 2025 Modern Endpoint Management. All rights reserved.'
    Description          = 'Custom PowerShell module for building and customizing OSDCloud WinPE media.'
    PowerShellVersion    = '5.1'

    # PowerShell Edition compatibility
    CompatiblePSEditions = @('Desktop', 'Core')

    # Functions to export
    FunctionsToExport    = @(
        'Add-OSDCloudCustomDriver',
        'Add-OSDCloudCustomScript',
        'Enable-OSDCloudTelemetry',
        'Get-PWsh7WrappedContent',
        'New-CustomOSDCloudISO',
        'New-OSDCloudCustomMedia',
        'Set-OSDCloudCustomSettings',
        'Set-OSDCloudTelemetry',
        'Test-OSDCloudCustomRequirements',
        'Update-CustomWimWithPwsh7',
        'Update-CustomWimWithPwsh7Advanced'
    )

    # Cmdlets to export
    CmdletsToExport      = @()

    # Variables to export - don't export any for security
    VariablesToExport    = @()

    # Aliases to export
    AliasesToExport      = @()

    # List of modules that must be imported before this module
    RequiredModules      = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData          = @{
        PSData = @{
            # Tags applied to this module for discoverability
            Tags                     = @('OSDCloud', 'WinPE', 'Deployment', 'Windows', 'ImageCustomization')

            # Project's URL - Update with actual repository URL when available
            # ProjectUri = 'https://github.com/your-org/OSDCloudCustomBuilder'

            # License URI - Update with actual repository URL when available
            # LicenseUri = 'https://github.com/your-org/OSDCloudCustomBuilder/blob/main/LICENSE'

            # Release notes - Update with actual repository URL when available
            # ReleaseNotes = 'https://github.com/your-org/OSDCloudCustomBuilder/blob/main/CHANGELOG.md'

            # Flag to indicate whether the module requires explicit user acceptance for install
            RequireLicenseAcceptance = $false
        }
    }
}
