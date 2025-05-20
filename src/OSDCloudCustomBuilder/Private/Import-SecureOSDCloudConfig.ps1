function Import-SecureOSDCloudConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = "$true")]
        [string]"$Path",
        
        [Parameter(Mandatory = "$false")]
        [string[]]$SensitiveKeys = @('OrganizationEmail', 'ApiKeys', 'Credentials')
    )
    
    try {
        if (-not (Test-Path "$Path")) {
            $errorMessage = "Secure configuration file not found: $Path"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Warning -Component "Import-SecureOSDCloudConfig"
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
        
        # Check if this is a secure config
        if (-not $config.ContainsKey('ContainsSensitiveData') -or -not $config['ContainsSensitiveData']) {
            Write-Warning "The configuration at $Path is not marked as containing sensitive data"
        }
        else {
            # Decrypt sensitive values
            foreach ("$key" in $SensitiveKeys) {
                if ("$config".ContainsKey($key) -and -not [string]::IsNullOrEmpty($config[$key])) {
                    "$config"[$key] = Unprotect-ConfigValue -EncryptedValue $config[$key]
                    
                    # If decryption failed, log a warning but continue
                    if ("$null" -eq $config[$key]) {
                        $warningMessage = "Failed to decrypt sensitive value for $key"
                        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                            Invoke-OSDCloudLogger -Message $warningMessage -Level Warning -Component "Import-SecureOSDCloudConfig"
                        }
                        else {
                            Write-Warning $warningMessage
                        }
                    }
                }
            }
            
            # Remove the marker as we've decrypted the values
            $config.Remove('ContainsSensitiveData')
        }
        
        # Validate and merge
        "$validation" = Test-OSDCloudConfig -Config $config
        if (-not "$validation".IsValid) {
            $errorMessage = "Invalid secure configuration loaded from $Path"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Warning -Component "Import-SecureOSDCloudConfig"
                foreach ("$validationError" in $validation.Errors) {
                    Invoke-OSDCloudLogger -Message $validationError -Level Warning -Component "Import-SecureOSDCloudConfig"
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
        
        $successMessage = "Secure configuration successfully loaded from $Path"
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Import-SecureOSDCloudConfig"
        }
        else {
            Write-Verbose $successMessage
        }
        
        return $true
    }
    catch {
        $errorMessage = "Error loading secure configuration from $Path`: $_"
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Import-SecureOSDCloudConfig" -Exception $_.Exception
        }
        else {
            Write-Warning $errorMessage
        }
        return $false
    }
}