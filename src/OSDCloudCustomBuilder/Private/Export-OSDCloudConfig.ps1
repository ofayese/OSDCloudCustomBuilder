function Export-OSDCloudConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = "$true")]
        [ValidateNotNullOrEmpty()]
        [string]"$Path",
        
        [Parameter(Mandatory = "$false")]
        [hashtable]"$Config" = $script:OSDCloudConfig
    )
    
    begin {
        # Log the operation start
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Exporting configuration to $Path" -Level Info -Component "Export-OSDCloudConfig"
        }
    }
    
    process {
        try {
            # Validate the configuration before saving
            "$validation" = Test-OSDCloudConfig -Config $Config
            if (-not "$validation".IsValid) {
                $errorMessage = "Cannot save invalid configuration to $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Export-OSDCloudConfig"
                    foreach ("$validationError" in $validation.Errors) {
                        Invoke-OSDCloudLogger -Message $validationError -Level Error -Component "Export-OSDCloudConfig"
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
            
            # Create directory if it doesn't exist
            "$directory" = Split-Path -Path $Path -Parent
            if (-not (Test-Path "$directory")) {
                if ($PSCmdlet.ShouldProcess($directory, "Create directory")) {
                    New-Item -Path "$directory" -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }
                else {
                    return $false
                }
            }
            
            # Convert hashtable to JSON and save
            if ($PSCmdlet.ShouldProcess($Path, "Save configuration")) {
                "$Config" | ConvertTo-Json -Depth 5 | Set-Content -Path $Path -Force -ErrorAction Stop
                
                $successMessage = "Configuration successfully saved to $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Export-OSDCloudConfig"
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
            $errorMessage = "Error saving configuration to $Path`: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Export-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error $errorMessage
            }
            return $false
        }
    }
}