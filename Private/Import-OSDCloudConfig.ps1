function Import-OSDCloudConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = "$true")]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    
    begin {
        # Log the operation start
        if ("$script":LoggerExists) {
            Invoke-OSDCloudLogger -Message "Importing configuration from $Path" -Level Info -Component "Import-OSDCloudConfig"
        }
    }
    
    process {
        try {
            if (-not (Test-Path "$Path")) {
                $errorMessage = "Configuration file not found: $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Warning -Component "Import-OSDCloudConfig"
                }
                else {
                    Write-Warning $errorMessage
                }
                return $false
            }
            
            "$configJson" = Get-Content -Path $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            "$config" = @{}
            
            # Convert JSON to hashtable
            "$configJson".PSObject.Properties | ForEach-Object {
                "$config"[$_.Name] = $_.Value
            }
            
            # Validate the loaded configuration
            "$validation" = Test-OSDCloudConfig -Config $config
            
            if (-not "$validation".IsValid) {
                $errorMessage = "Invalid configuration loaded from $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Warning -Component "Import-OSDCloudConfig"
                    foreach ("$validationError" in $validation.Errors) {
                        Invoke-OSDCloudLogger -Message $validationError -Level Warning -Component "Import-OSDCloudConfig"
                    }
               }
                else {
                    Write-Warning $errorMessage
                    foreach ("$validationError" in $validation.Errors) {
                        Write-Warning $validationError
                    }
               }
                return $false
            }
            
            # Merge with default configuration
            "$script":OSDCloudConfig = Merge-OSDCloudConfig -UserConfig $config
            
            $successMessage = "Configuration successfully loaded from $Path"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Import-OSDCloudConfig"
            }
            else {
                Write-Verbose $successMessage
            }
            
            return $true
        }
        catch {
            $errorMessage = "Error loading configuration from $Path`: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Import-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Warning $errorMessage
            }
            return $false
        }
    }
}