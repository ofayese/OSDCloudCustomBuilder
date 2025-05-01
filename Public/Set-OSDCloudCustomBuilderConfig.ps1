# Function: Set-OSDCloudCustomBuilderConfig
# Author: Oluwaseun Fayese
# Company: Modern Endpoint Management
# Last Modified: April 19, 2025

<#
.SYNOPSIS
    Sets configuration options for the OSDCloudCustomBuilder module.
.DESCRIPTION
    This function allows you to configure various aspects of the OSDCloudCustomBuilder module,
    including paths, PowerShell 7 settings, telemetry options, and more. Changes are persisted
    to the module configuration and will be available across sessions.
.PARAMETER Config
    A hashtable containing configuration settings to apply. The hashtable can include the
    following sections:
    - PowerShell7: Settings related to PowerShell 7 integration
    - Paths: File paths used by the module
    - Timeouts: Timeout values for various operations
    - Telemetry: Telemetry collection settings
.PARAMETER ResetToDefaults
    If specified, resets all configuration settings to their default values.
.PARAMETER PassThru
    If specified, returns the updated configuration object.
.EXAMPLE
    Set-OSDCloudCustomBuilderConfig -Config @{
        PowerShell7 = @{
            Version = "7.5.0"
            CacheEnabled = $true
        }
        Paths = @{
            WorkingDirectory = "C:\OSDCloud\Temp"
        }
    }
.EXAMPLE
    Set-OSDCloudCustomBuilderConfig -ResetToDefaults
.NOTES
    Changes made using this function will persist across PowerShell sessions.
#>
function Set-OSDCloudCustomBuilderConfig {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Config')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Config')]
        [hashtable]$Config,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Reset')]
        [switch]$ResetToDefaults,
        
        [Parameter(ParameterSetName = 'Config')]
        [Parameter(ParameterSetName = 'Reset')]
        [switch]$PassThru
    )
    
    begin {
        # Ensure the module is loaded
        if (-not (Get-Module -Name OSDCloudCustomBuilder)) {
            Write-Warning "OSDCloudCustomBuilder module not loaded. Attempting to load..."
            Import-Module -Name OSDCloudCustomBuilder -ErrorAction Stop
        }
        
        # Get current configuration
        try {
            $currentConfig = Get-ModuleConfiguration -ErrorAction Stop
        }
        catch {
            Write-Warning "Could not retrieve current configuration: $_"
            $currentConfig = @{
                PowerShell7 = @{
                    Version = "7.5.0"
                    CacheEnabled = $true
                }
                Paths = @{
                    WorkingDirectory = "$env:TEMP\OSDCloud"
                    CachePath = "$env:TEMP\OSDCloudCache"
                    LogPath = "$env:TEMP\OSDCloudLogs"
                }
                Timeouts = @{
                    Download = 600
                    Mount = 300
                    Dismount = 300
                    Job = 300
                }
                Telemetry = @{
                    Enabled = $false
                    Path = "$env:TEMP\OSDCloudTelemetry"
                    RetentionDays = 30
                }
            }
        }
    }
    
    process {
        if ($ResetToDefaults) {
            if ($PSCmdlet.ShouldProcess("Module configuration", "Reset to defaults")) {
                try {
                    Reset-ModuleConfiguration -ErrorAction Stop
                    Write-Verbose "Configuration reset to defaults"
                    
                    if ($PassThru) {
                        $updatedConfig = Get-ModuleConfiguration -ErrorAction Stop
                        return $updatedConfig
                    }
                }
                catch {
                    Write-Error "Failed to reset configuration: $_"
                }
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess("Module configuration", "Update configuration")) {
                try {
                    # Merge the provided configuration with the current configuration
                    $newConfig = $currentConfig.Clone()
                    
                    foreach ($section in $Config.Keys) {
                        if (-not $newConfig.ContainsKey($section)) {
                            $newConfig[$section] = @{}
                        }
                        
                        foreach ($key in $Config[$section].Keys) {
                            $newConfig[$section][$key] = $Config[$section][$key]
                        }
                    }
                    
                    # Update the configuration
                    Update-ModuleConfiguration -Config $newConfig -ErrorAction Stop
                    Write-Verbose "Configuration updated successfully"
                    
                    if ($PassThru) {
                        $updatedConfig = Get-ModuleConfiguration -ErrorAction Stop
                        return $updatedConfig
                    }
                }
                catch {
                    Write-Error "Failed to update configuration: $_"
                }
            }
        }
    }
}

Export-ModuleMember -Function Set-OSDCloudCustomBuilderConfig