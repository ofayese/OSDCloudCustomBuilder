<#
.SYNOPSIS
    Set-OSDCloudCustomSettings - Brief summary of what the function does.

.DESCRIPTION
    Detailed description for Set-OSDCloudCustomSettings. This should explain the purpose, usage, and examples.

.EXAMPLE
    PS> Set-OSDCloudCustomSettings

.NOTES
    Author: YourName
    Date: 1748138720.8589237
#>

function Set-OSDCloudCustomSettings {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Settings,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$NoValidation
    )

    begin {
        # Initialize logging
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Starting custom settings update" -Level Info -Component "Set-OSDCloudCustomSettings"
        }
    }

    process {
        try {
            # Get current configuration
            $currentConfig = Get-OSDCloudConfig -ErrorAction Stop

            # Create merged configuration
            $newConfig = $currentConfig.Clone()
            foreach ($key in $Settings.Keys) {
                if (($currentConfig.ContainsKey($key)) -and (-not $Force)) {
                    Write-Warning "Setting '$key' already exists. Use -Force to overwrite."
                    continue
                }
                $newConfig[$key] = $Settings[$key]
            }

            # Validate new configuration unless skipped
            if (-not $NoValidation) {
                $validation = Test-OSDCloudConfig -Config $newConfig
                if (-not $validation.IsValid) {
                    $errorMsg = "Invalid configuration settings:`n" + ($validation.Errors -join "`n")
                    Write-Error $errorMsg
                    return
                }
            }

            if ($PSCmdlet.ShouldProcess("OSDCloud Configuration", "Update settings")) {
                # Update configuration
                foreach ($key in $Settings.Keys) {
                    $script:OSDCloudConfig[$key] = $Settings[$key]
                }

                # Update metadata
                $script:OSDCloudConfig['LastModified'] = (Get-Date).ToString('o')
                $script:OSDCloudConfig['ModifiedBy'] = $env:USERNAME

                # Add change record
                $changeRecord = @{
                    Timestamp = (Get-Date).ToString('o')
                    User = $env:USERNAME
                    Changes = $Settings
                    ValidationSkipped = $NoValidation
                }

                if (-not $script:OSDCloudConfig.ContainsKey('ChangeHistory')) {
                    $script:OSDCloudConfig['ChangeHistory'] = @()
                }
                $script:OSDCloudConfig['ChangeHistory'] = @($changeRecord) + $script:OSDCloudConfig['ChangeHistory']

                # Save configuration to disk
                $configPath = Join-Path -Path $env:TEMP -ChildPath "OSDCloud\Config\settings.json"
                $parentPath = Split-Path -Path $configPath -Parent
                if (-not (Test-Path $parentPath)) {
                    New-Item -Path $parentPath -ItemType Directory -Force | Out-Null
                }

                $script:OSDCloudConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Force

                # Log success
                $successMsg = "Successfully updated OSDCloud settings"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $successMsg -Level Info -Component "Set-OSDCloudCustomSettings"
                }
                else {
                    Write-Verbose $successMsg
                }
            }
        }
        catch {
            $errorMsg = "Failed to update settings: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMsg -Level Error -Component "Set-OSDCloudCustomSettings" -Exception $_.Exception
            }
            Write-Error $errorMsg
        }
    }

    end {
        # Final logging
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Completed settings update process" -Level Info -Component "Set-OSDCloudCustomSettings"
        }
    }
}

Export-ModuleMember -Function Set-OSDCloudCustomSettings
