<#
.SYNOPSIS
    Add-OSDCloudCustomDriver - Brief summary of what the function does.

.DESCRIPTION
    Detailed description for Add-OSDCloudCustomDriver. This should explain the purpose, usage, and examples.

.EXAMPLE
    PS> Add-OSDCloudCustomDriver

.NOTES
    Author: YourName
    Date: 1748138720.8589237
#>


function Add-OSDCloudCustomDriver {
    <#
    .SYNOPSIS
        Adds and catalogs drivers for OSDCloud custom Windows images.

    .DESCRIPTION
        The Add-OSDCloudCustomDriver function copies driver packages to the OSDCloud workspace
        and creates a catalog file documenting the included drivers. It supports different levels
        of cataloging detail and validates driver paths before processing.

    .PARAMETER DriverPath
        The path to a driver package (.inf file) or directory containing multiple drivers.
        The path must exist and be accessible.

    .PARAMETER CatalogLevel
        Specifies the level of detail for driver cataloging:
        - Basic: Lists only driver names and directories
        - Standard: Includes driver details and class descriptions (Default)
        - Advanced: Provides full driver information including hardware IDs

    .PARAMETER Force
        Override existing driver packages in the destination without prompting.
        By default, the function will warn and skip if a driver already exists.

    .EXAMPLE
        Add-OSDCloudCustomDriver -DriverPath "C:\Drivers\Network"

        Adds all drivers from the specified directory using standard cataloging.

    .EXAMPLE
        Add-OSDCloudCustomDriver -DriverPath "C:\Drivers\Display\display.inf" -CatalogLevel Advanced -Force

        Adds a specific driver with detailed cataloging, overwriting if it exists.

    .NOTES
        File Name      : Add-OSDCloudCustomDriver.ps1
        Version       : 1.0
        Author        : Modern Endpoint Management
        Creation Date : May 23, 2025
        Requires     : PowerShell 5.1 or later
                      Windows ADK
                      Administrator privileges

    .LINK
        https://github.com/your-org/OSDCloudCustomBuilder

    #>
    [OutputType([void])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,
                  Position=0,
                  ValueFromPipeline=$true,
                  ValueFromPipelineByPropertyName=$true,
                  HelpMessage="Path to the driver or driver directory")]
        [ValidateNotNullOrEmpty()]
        [string]$DriverPath,

        [Parameter(HelpMessage="Level of detail for driver cataloging")]
        [ValidateSet('Basic', 'Standard', 'Advanced')]
        [string]$CatalogLevel = 'Standard',

        [Parameter(HelpMessage="Force overwrite of existing drivers")]
        [switch]$Force
    )    begin {
        $callerName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$callerName] Beginning driver addition process"

        try {
            # Check for admin privileges
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            if (-not $isAdmin) {
                throw "Administrator privileges are required to add drivers"
            }

            # Log function start
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message "Starting driver addition process" -Level Info -Component $callerName
            }

            # Validate driver path
            if (-not (Test-Path -Path $DriverPath)) {
                throw "Driver path not found: $DriverPath"
            }

            # Validate driver path contains .inf files if it's a directory
            if ((Get-Item $DriverPath).PSIsContainer) {
                $infFiles = Get-ChildItem -Path $DriverPath -Filter "*.inf" -Recurse
                if (-not $infFiles) {
                    throw "No driver (.inf) files found in specified path: $DriverPath"
                }
            }
        }
        catch {
            $errorMsg = $_
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMsg -Level Error -Component $callerName -Exception $_.Exception
            }
            Write-Error $errorMsg
            return
        }
    }

    process {
        try {
            # Get workspace configuration
            $config = Get-OSDCloudConfig -ErrorAction Stop

            # Determine target path for drivers
            $driversRoot = Join-Path -Path $config.TempWorkspacePath -ChildPath "Drivers"
            if (-not (Test-Path $driversRoot)) {
                New-Item -Path $driversRoot -ItemType Directory -Force | Out-Null
            }

            # Copy drivers with proper categorization
            $destinationPath = Join-Path -Path $driversRoot -ChildPath (Split-Path -Leaf $DriverPath)
            if ($PSCmdlet.ShouldProcess($destinationPath, "Add driver")) {
                if ((Test-Path $destinationPath) -and (-not $Force)) {
                    Write-Warning "Driver already exists at $destinationPath. Use -Force to overwrite."
                    return
                }

                Copy-Item -Path $DriverPath -Destination $destinationPath -Force -Recurse

                # Create driver catalog based on level
                switch ($CatalogLevel) {
                    'Advanced' {
                        # Create detailed catalog with hardware IDs
                        Get-WindowsDriver -Path $destinationPath -Recurse |
                        Select-Object OriginalFileName, Driver, ClassDescription, ProviderName, Date |
                        Export-Csv -Path "$destinationPath\catalog.csv" -NoTypeInformation
                    }
                    'Standard' {
                        # Basic catalog with essential info
                        Get-WindowsDriver -Path $destinationPath -Recurse |
                        Select-Object Driver, ClassDescription |
                        Export-Csv -Path "$destinationPath\catalog.csv" -NoTypeInformation
                    }
                    'Basic' {
                        # Simple driver list
                        Get-ChildItem -Path $destinationPath -Recurse -Filter "*.inf" |
                        Select-Object Name, Directory |
                        Export-Csv -Path "$destinationPath\catalog.csv" -NoTypeInformation
                    }
                }

                # Log success
                $successMsg = "Successfully added driver from $DriverPath"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $successMsg -Level Info -Component "Add-OSDCloudCustomDriver"
                }
                else {
                    Write-Verbose $successMsg
                }
            }
        }
        catch {
            $errorMsg = "Failed to add driver: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMsg -Level Error -Component "Add-OSDCloudCustomDriver" -Exception $_.Exception
            }
            Write-Error $errorMsg
        }
    }

    end {
        # Final logging
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Completed driver addition process" -Level Info -Component "Add-OSDCloudCustomDriver"
        }
    }
}

Export-ModuleMember -Function Add-OSDCloudCustomDriver
