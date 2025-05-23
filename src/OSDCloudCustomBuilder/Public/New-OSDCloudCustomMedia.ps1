function New-OSDCloudCustomMedia {
    <#
    .SYNOPSIS
        Creates a new customized OSDCloud WinPE media.
    .DESCRIPTION
        Creates a new customized OSDCloud WinPE media with organization branding
        and customized settings.
    .PARAMETER Name
        The name of the custom media to create.
    .PARAMETER Path
        The path where the custom media should be created.
    .PARAMETER BrandingLogo
        Path to a logo file to use for branding.
    .PARAMETER BackgroundColor
        The background color to use for the WinPE environment.
    .PARAMETER WindowsVersion
        The version of Windows to include drivers for.
    .EXAMPLE
        New-OSDCloudCustomMedia -Name "Contoso" -Path "C:\OSDCloud" -BrandingLogo "C:\Logos\contoso.png"
    #>
    [OutputType([void])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter()]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$BrandingLogo,

        [Parameter()]
        [ValidateSet('Blue', 'Green', 'Red', 'Orange', 'Purple', 'Cyan', 'Gray', 'Black')]
        [string]$BackgroundColor = 'Blue',

        [Parameter()]
        [ValidateSet('Windows 10', 'Windows 11')]
        [string]$WindowsVersion = 'Windows 11'
    )

    begin {
        if (-not (Test-IsAdmin)) {
            Write-LogMessage -Message "This function requires administrator privileges." -Level Fatal
        }

        Write-LogMessage -Message "Starting creation of custom OSDCloud media '$Name'" -Level Info
    }

    process {
        try {
            # Create the base directory
            $mediaPath = Join-Path -Path $Path -ChildPath $Name
            if (-not (Test-Path -Path $mediaPath)) {
                New-Item -Path $mediaPath -ItemType Directory -Force | Out-Null
                Write-LogMessage -Message "Created directory: $mediaPath" -Level Debug
            }

            # Create OSDCloud workspace using the standard module
            Write-LogMessage -Message "Creating OSDCloud workspace..." -Level Info
            New-OSDCloudWorkspace -WorkspacePath $mediaPath

            # Apply branding if specified
            if ($BrandingLogo) {
                Write-LogMessage -Message "Applying branding logo" -Level Info
                # Placeholder for branding logic
                Copy-Item -Path $BrandingLogo -Destination (Join-Path -Path $mediaPath -ChildPath "Media\Logo.png") -Force
            }

            # Apply background color
            Write-LogMessage -Message "Applying background color: $BackgroundColor" -Level Info
            # Placeholder for background color logic

            # Add Windows version-specific customizations
            Write-LogMessage -Message "Configuring for $WindowsVersion" -Level Info
            # Placeholder for Windows version customization logic

            Write-LogMessage -Message "OSDCloud media creation completed successfully" -Level Info
        }
        catch {
            Write-LogMessage -Message "Failed to create OSDCloud media: $_" -Level Error
            throw $_
        }
    }

    end {
        Write-LogMessage -Message "Custom OSDCloud media creation completed" -Level Info
    }
}
