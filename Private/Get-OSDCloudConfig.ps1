function Get-OSDCloudConfig {
    [CmdletBinding()]
    param()
    
    begin {
        # Log the operation
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Retrieving current configuration" -Level Verbose -Component "Get-OSDCloudConfig"
        }
    }
    
    process {
        try {
            # Check if configuration exists, initialize with defaults if not
            if (-not (Get-Variable -Name OSDCloudConfig -Scope Script -ErrorAction SilentlyContinue)) {
                # Initialize with default configuration
                $script:OSDCloudConfig = @{
                    LogFilePath = Join-Path -Path $env:TEMP -ChildPath "OSDCloudCustomBuilder.log"
                    ISOOutputPath = "$env:USERPROFILE\Downloads"
                    TelemetryEnabled = $false
                    VerboseLogging = $false
                    DebugLogging = $false
                    PowerShell7Version = "7.5.0"
                }
                
                # Try to load from config file if it exists
                $configPath = Join-Path -Path $script:ModuleRoot -ChildPath "config.json"
                if (Test-Path -Path $configPath) {
                    try {
                        $fileConfig = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                        
                        # Override defaults with file settings
                        foreach ($prop in $fileConfig.PSObject.Properties) {
                            $script:OSDCloudConfig[$prop.Name] = $prop.Value
                        }
                    }
                    catch {
                        Invoke-OSDCloudLogger -Message "Failed to load configuration from $configPath. Using defaults." -Level Warning
                    }
                }
            }
            
            # Return a clone of the configuration to prevent unintended modifications
            $configClone = @{}
            foreach ($key in $script:OSDCloudConfig.Keys) {
                if ($script:OSDCloudConfig[$key] -is [hashtable]) {
                    $configClone[$key] = $script:OSDCloudConfig[$key].Clone()
                }
                elseif ($script:OSDCloudConfig[$key] -is [array]) {
                    $configClone[$key] = $script:OSDCloudConfig[$key].Clone()
                }
                else {
                    $configClone[$key] = $script:OSDCloudConfig[$key]
                }
            }
            
            return $configClone
        }
        catch {
            $errorMessage = "Error retrieving configuration: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Get-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error $errorMessage
            }
            
            # Return an empty hashtable in case of error
            return @{}
        }
    }
}