# Function: Update-ModuleConfiguration
# Author: Oluwaseun Fayese
# Company: Modern Endpoint Management
# Last Modified: April 19, 2025

<#
.SYNOPSIS
    Updates the configuration for the OSDCloudCustomBuilder module.
.DESCRIPTION
    This function updates the configuration settings for the OSDCloudCustomBuilder module
    and persists the changes to the configuration file. It handles merging the new configuration
    with the existing one and validates the configuration before saving.
.PARAMETER Config
    A hashtable containing the new configuration settings to apply.
.EXAMPLE
    Update-ModuleConfiguration -Config @{
        PowerShell7 = @{
            Version = "7.5.0"
        }
    }
.NOTES
    This function is used internally by other module functions.
#>
function Update-ModuleConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    process {
        try {
            # Validate the configuration
            $validation = Test-OSDCloudConfig -Config $Config -ErrorAction Stop
            
            if (-not $validation.IsValid) {
                $errorMessages = $validation.Errors -join "`n"
                Write-Error "Invalid configuration: $errorMessages"
                return $false
            }
            
            # Update the module configuration
            $script:ModuleConfig = $Config.Clone()
            
            # Save the configuration to file
            $configPath = Join-Path -Path $script:ModuleRoot -ChildPath "config.json"
            
            if ($PSCmdlet.ShouldProcess($configPath, "Save configuration")) {
                $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Force
                Write-Verbose "Configuration saved to $configPath"
                
                # Add a change record
                Add-ConfigChangeRecord -Config $Config
                
                return $true
            }
        }
        catch {
            Write-Error "Failed to update configuration: $_"
            return $false
        }
    }
}

Export-ModuleMember -Function Update-ModuleConfiguration