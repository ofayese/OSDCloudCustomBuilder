<#
.SYNOPSIS
    Adds custom PowerShell scripts to OSDCloud deployment media.

.DESCRIPTION
    The Add-OSDCloudCustomScript function integrates custom PowerShell scripts into the OSDCloud
    deployment process. Scripts can be executed at different phases of the deployment to customize
    the installation experience, configure settings, or install additional software.

.PARAMETER ScriptPath
    The path to the PowerShell script file (.ps1) to be added to the deployment media.

.PARAMETER ScriptType
    Specifies when the script should be executed during deployment:
    - Startup: During WinPE boot phase
    - Setup: During Windows installation
    - Customize: After Windows installation completes (Default)

.PARAMETER Force
    Forces overwrite of existing scripts without confirmation.

.PARAMETER RunOrder
    Numeric value (default: 50) that determines execution order when multiple scripts exist.

.EXAMPLE
    PS> Add-OSDCloudCustomScript -ScriptPath "C:\Scripts\CustomConfig.ps1"

    Adds a custom configuration script to run after Windows installation.

.EXAMPLE
    PS> Add-OSDCloudCustomScript -ScriptPath "C:\Scripts\Setup.ps1" -ScriptType Setup -RunOrder 10

    Adds a setup script to run during Windows installation with high priority.

.NOTES
    Author: OSDCloud Team
    Date: 2025-05-26
    Requires: PowerShell 5.1 or later
#>

function Add-OSDCloudCustomScript {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter()]
        [ValidateSet('Startup', 'Setup', 'Customize')]
        [string]$ScriptType = 'Customize',

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [string]$RunOrder = "50"
    )

    begin {
        # Initialize logging
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Starting script addition process" -Level Info -Component "Add-OSDCloudCustomScript"
        }

        # Validate script path
        if (-not (Test-Path -Path $ScriptPath)) {
            $errorMsg = "Script not found: $ScriptPath"
            Write-Error $errorMsg
            return
        }

        # Validate script extension
        $extension = [System.IO.Path]::GetExtension($ScriptPath)
        if ($extension -notin @('.ps1', '.cmd', '.bat')) {
            $errorMsg = "Invalid script type. Supported extensions: .ps1, .cmd, .bat"
            Write-Error $errorMsg
            return
        }
    }

    process {
        try {
            # Get workspace configuration
            $config = Get-OSDCloudConfig -ErrorAction Stop

            # Determine target path based on script type
            $scriptsRoot = Join-Path -Path $config.TempWorkspacePath -ChildPath "Scripts"
            $scriptTypeFolder = Join-Path -Path $scriptsRoot -ChildPath $ScriptType
            if (-not (Test-Path $scriptTypeFolder)) {
                New-Item -Path $scriptTypeFolder -ItemType Directory -Force | Out-Null
            }

            # Create numbered filename for ordering
            $scriptName = [System.IO.Path]::GetFileName($ScriptPath)
            $orderedScriptName = "{0:D2}-{1}" -f [int]$RunOrder, $scriptName
            $destinationPath = Join-Path -Path $scriptTypeFolder -ChildPath $orderedScriptName

            if ($PSCmdlet.ShouldProcess($destinationPath, "Add script")) {
                if ((Test-Path $destinationPath) -and (-not $Force)) {
                    Write-Warning "Script already exists at $destinationPath. Use -Force to overwrite."
                    return
                }

                # Copy and process script
                Copy-Item -Path $ScriptPath -Destination $destinationPath -Force

                # Add execution wrapper for PowerShell scripts
                if ($extension -eq '.ps1') {
                    $content = Get-Content -Path $destinationPath -Raw
                    $wrappedContent = @"
try {
    Write-Host "Executing custom script: $orderedScriptName"
    $content
}
catch {
    Write-Error "Error in custom script $orderedScriptName`: `$_"
    throw
}
"@
                    Set-Content -Path $destinationPath -Value $wrappedContent -Force
                }

                # Create metadata file
                $metadata = @{
                    ScriptName   = $scriptName
                    ScriptType   = $ScriptType
                    RunOrder     = $RunOrder
                    DateAdded    = (Get-Date).ToString('o')
                    OriginalPath = $ScriptPath
                }
                $metadataPath = $destinationPath + '.json'
                $metadata | ConvertTo-Json | Set-Content -Path $metadataPath -Force

                # Log success
                $successMsg = "Successfully added script from $ScriptPath as $orderedScriptName"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $successMsg -Level Info -Component "Add-OSDCloudCustomScript"
                } else {
                    Write-Verbose $successMsg
                }
            }
        } catch {
            $errorMsg = "Failed to add script: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMsg -Level Error -Component "Add-OSDCloudCustomScript" -Exception $_.Exception
            }
            Write-Error $errorMsg
        }
    }

    end {
        # Final logging
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Completed script addition process" -Level Info -Component "Add-OSDCloudCustomScript"
        }
    }
}

Export-ModuleMember -Function Add-OSDCloudCustomScript
