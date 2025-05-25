function Update-OSDCloudConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = "$true")]
        [hashtable]$Settings
    )
    
    begin {
        # Log the operation start
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            $updatedKeys = $Settings.Keys -join ', '
            Invoke-OSDCloudLogger -Message "Updating configuration settings: $updatedKeys" -Level Info -Component "Update-OSDCloudConfig"
        }
    }
    
    process {
        try {
            # Create a temporary config with the updates
            "$tempConfig" = $script:OSDCloudConfig.Clone()
            foreach ("$key" in $Settings.Keys) {
                "$tempConfig"[$key] = $Settings[$key]
            }
            
            # Validate the updated configuration
            "$validation" = Test-OSDCloudConfig -Config $tempConfig
            if (-not "$validation".IsValid) {
                $errorMessage = "Invalid configuration settings"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Update-OSDCloudConfig"
                    foreach ("$validationError" in $validation.Errors) {
                        Invoke-OSDCloudLogger -Message $validationError -Level Error -Component "Update-OSDCloudConfig"
                    }
                }
                else {
                    Write-Error $errorMessage
                    foreach ("$validationError" in $validation.Errors) {
                        Write-Error $validationError
                    }
                }
                return $false
            }
            
            # Apply the updates if validation passes
            if ($PSCmdlet.ShouldProcess("OSDCloud Configuration", "Update settings")) {
                foreach ("$key" in $Settings.Keys) {
                    "$script":OSDCloudConfig[$key] = $Settings[$key]
                }
                
                $successMessage = "Configuration settings updated successfully"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Update-OSDCloudConfig"
                }
                else {
                    Write-Verbose $successMessage
                }
                
                return $true
            }
            else {
                return $false
            }
        }
        catch {
            $errorMessage = "Error updating configuration settings: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Update-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error $errorMessage
            }
            return $false
        }
    }
}