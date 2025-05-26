<#
.SYNOPSIS
    Add-OSDCloudCustomScript - Performs a key function for OSDCloud customization.

.DESCRIPTION
    Detailed explanation for Add-OSDCloudCustomScript. This function plays a role in OSDCloud automation and system prep workflows.

.EXAMPLE
    PS> Add-OSDCloudCustomScript -Param1 Value1



.NOTES
    Author: OSDCloud Team
    Date: 2025-05-26
#>

<#
.SYNOPSIS
    Add-OSDCloudCustomScript - Brief summary of what the function does.

.DESCRIPTION
    Detailed description for Add-OSDCloudCustomScript. This should explain the purpose, usage, and examples.

.EXAMPLE
    PS> Add-OSDCloudCustomScript

.NOTES
    Author: YourName
    Date: 1748138720.8589237
#>

function Add-OSDCloudCustomScript {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
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
                    ScriptName = $scriptName
                    ScriptType = $ScriptType
                    RunOrder = $RunOrder
                    DateAdded = (Get-Date).ToString('o')
                    OriginalPath = $ScriptPath
                }
                $metadataPath = $destinationPath + '.json'
                $metadata | ConvertTo-Json | Set-Content -Path $metadataPath -Force

                # Log success
                $successMsg = "Successfully added script from $ScriptPath as $orderedScriptName"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $successMsg -Level Info -Component "Add-OSDCloudCustomScript"
                }
                else {
                    Write-Verbose $successMsg
                }
            }
        }
        catch {
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
