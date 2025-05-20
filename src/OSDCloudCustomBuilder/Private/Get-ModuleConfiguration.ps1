# Function: Get-ModuleConfiguration
# Author: Oluwaseun Fayese
# Company: Modern Endpoint Management
# Last Modified: April 19, 2025

<#
.SYNOPSIS
    Retrieves the current configuration for the OSDCloudCustomBuilder module.
.DESCRIPTION
    This function returns the current configuration settings for the OSDCloudCustomBuilder module,
    including paths, PowerShell 7 settings, timeouts, and telemetry options. The configuration
    is loaded from a persistent store if available, or defaults are used.
.PARAMETER Force
    If specified, forces a reload of the configuration from the persistent store.
.EXAMPLE
    Get-ModuleConfiguration
.EXAMPLE
    Get-ModuleConfiguration -Force
.NOTES
    This function is used internally by other module functions.
#>
function Get-ModuleConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        # Define the path to the configuration file
        $configPath = Join-Path -Path $script:ModuleRoot -ChildPath "config.json"
        
        # Define default configuration
        $defaultConfig = @{
            PowerShell7 = @{
                Version = "7.5.0"
                CacheEnabled = $true
                VersionsToKeep = 2
            }
            PowerShellVersions = @{
                Default = "7.5.0"
                Supported = @("7.3.4", "7.4.1", "7.5.0")
                Hashes = @{
                    "7.3.4" = "6A1B82BA6FB3C66C25286AE2CBFC151F7A7D71F8C8C1D6AE3B6E1151BAA9C008"
                    "7.4.1" = "F7D12B83D0F9D5A0AF4DA6B1D2F5F9D3C6D5E8F2E4B7C9D0A1B2C3D4E5F6A7B8"
                    "7.5.0" = "E9D4F5C6D7B8A9C0B1D2E3F4A5B6C7D8E9F0A1B2C3D4E5F6A7B8C9D0E1F2A3B4"
                }
            }
            DownloadSources = @{
                PowerShell = "https://github.com/PowerShell/PowerShell/releases/download/v{0}/PowerShell-{0}-win-x64.zip"
            }
            Paths = @{
                WorkingDirectory = "$env:TEMP\OSDCloud"
                Cache = "$env:TEMP\OSDCloudCache"
                Logs = "$env:TEMP\OSDCloudLogs"
                Scripts = "$env:TEMP\OSDCloudScripts"
                Temp = "$env:TEMP\OSDCloudTemp"
            }
            Timeouts = @{
                Download = 600
                Mount = 300
                Dismount = 300
                Job = 300
                Cache = 86400
            }
            Telemetry = @{
                Enabled = $false
                Path = "$env:TEMP\OSDCloudTelemetry"
                RetentionDays = 30
                DetailLevel = "Basic"
                AnonymizeHostname = $true
                IncludeSystemInfo = $false
            }
            Logging = @{
                Enabled = $true
                Path = "$env:TEMP\OSDCloudLogs"
                Level = "Info"
                MaxSize = 10MB
                MaxFiles = 5
                IncludeTimestamp = $true
                IncludeSource = $true
            }
        }
        
        # Static configuration cache
        if (-not $script:ModuleConfig -or $Force) {
            $script:ModuleConfig = $defaultConfig.Clone()
            
            # Try to load configuration from file
            if (Test-Path -Path $configPath) {
                try {
                    $savedConfig = Get-Content -Path $configPath -Raw | ConvertFrom-Json -ErrorAction Stop
                    
                    # Convert to hashtable
                    $savedConfigHashtable = @{}
                    foreach ($property in $savedConfig.PSObject.Properties) {
                        if ($property.Value -is [PSCustomObject]) {
                            $sectionHashtable = @{}
                            foreach ($subProperty in $property.Value.PSObject.Properties) {
                                $sectionHashtable[$subProperty.Name] = $subProperty.Value
                            }
                            $savedConfigHashtable[$property.Name] = $sectionHashtable
                        }
                        else {
                            $savedConfigHashtable[$property.Name] = $property.Value
                        }
                    }
                    
                    # Merge with default configuration
                    foreach ($section in $savedConfigHashtable.Keys) {
                        if (-not $script:ModuleConfig.ContainsKey($section)) {
                            $script:ModuleConfig[$section] = @{}
                        }
                        
                        if ($savedConfigHashtable[$section] -is [hashtable]) {
                            foreach ($key in $savedConfigHashtable[$section].Keys) {
                                $script:ModuleConfig[$section][$key] = $savedConfigHashtable[$section][$key]
                            }
                        }
                        else {
                            $script:ModuleConfig[$section] = $savedConfigHashtable[$section]
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to load configuration from $configPath. Using defaults. Error: $_"
                }
            }
            
            # Create directories
            foreach ($directory in @($script:ModuleConfig.Paths.Cache, $script:ModuleConfig.Paths.Logs)) {
                if (-not (Test-Path -Path $directory -PathType Container)) {
                    try {
                        New-Item -Path $directory -ItemType Directory -Force | Out-Null
                        Write-Verbose "Created directory: $directory"
                    }
                    catch {
                        Write-Warning "Failed to create directory $directory: $_"
                    }
                }
            }
        }
    }
    
    process {
        return $script:ModuleConfig
    }
}

Export-ModuleMember -Function Get-ModuleConfiguration