# Function: Reset-ModuleConfiguration
# Author: Oluwaseun Fayese
# Company: Modern Endpoint Management
# Last Modified: April 19, 2025

<#
.SYNOPSIS
    Resets the OSDCloudCustomBuilder module configuration to default values.
.DESCRIPTION
    This function resets all configuration settings for the OSDCloudCustomBuilder module
    to their default values. It removes any customizations that have been applied and
    restores the original configuration.
.PARAMETER Force
    If specified, forces the reset without prompting for confirmation.
.EXAMPLE
    Reset-ModuleConfiguration
.EXAMPLE
    Reset-ModuleConfiguration -Force
.NOTES
    This function is used internally by other module functions.
#>
function Reset-ModuleConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    process {
        if ($Force -or $PSCmdlet.ShouldProcess("Module configuration", "Reset to defaults")) {
            try {
                # Remove the configuration file if it exists
                $configPath = Join-Path -Path $script:ModuleRoot -ChildPath "config.json"
                if (Test-Path -Path $configPath) {
                    Remove-Item -Path $configPath -Force
                    Write-Verbose "Removed configuration file: $configPath"
                }
                
                # Clear the module configuration cache
                $script:ModuleConfig = $null
                
                # Reload the configuration with defaults
                $config = Get-ModuleConfiguration -Force
                Write-Verbose "Configuration reset to defaults"
                
                # Add a change record
                Add-ConfigChangeRecord -Config $config -Action "Reset"
                
                return $true
            }
            catch {
                Write-Error "Failed to reset configuration: $_"
                return $false
            }
        }
    }
}

Export-ModuleMember -Function Reset-ModuleConfiguration