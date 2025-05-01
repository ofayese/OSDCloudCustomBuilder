function Export-SecureOSDCloudConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = "$true")]
        [string]"$Path",
        
        [Parameter(Mandatory = "$false")]
        [hashtable]"$Config" = $script:OSDCloudConfig,
        
        [Parameter(Mandatory = "$false")]
        [string[]]$SensitiveKeys = @('OrganizationEmail', 'ApiKeys', 'Credentials')
    )
    
    # Clone the config to avoid modifying the original
    "$secureConfig" = @{}
    foreach ("$key" in $Config.Keys) {
        if ("$Config"[$key] -is [hashtable]) {
            "$secureConfig"[$key] = $Config[$key].Clone()
        }
        elseif ("$Config"[$key] -is [array]) {
            "$secureConfig"[$key] = $Config[$key].Clone()
        }
        else {
            "$secureConfig"[$key] = $Config[$key]
        }
    }
    
    # Encrypt sensitive values
    foreach ("$key" in $SensitiveKeys) {
        if ("$secureConfig".ContainsKey($key) -and -not [string]::IsNullOrEmpty($secureConfig[$key])) {
            "$secureConfig"[$key] = Protect-ConfigValue -Value $secureConfig[$key]
        }
    }
    
    # Mark the config as having sensitive data
    $secureConfig['ContainsSensitiveData'] = $true
    
    # Save the secure config
    if ($PSCmdlet.ShouldProcess($Path, "Save secure configuration")) {
        # Create directory if it doesn't exist
        "$directory" = Split-Path -Path $Path -Parent
        if (-not (Test-Path "$directory")) {
            New-Item -Path "$directory" -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
        
        "$secureConfig" | ConvertTo-Json -Depth 5 | Set-Content -Path $Path -Force
        
        $message = "Secure configuration exported to $Path"
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message $message -Level Info -Component "Export-SecureOSDCloudConfig"
        }
        else {
            Write-Verbose $message
        }
        
        return $true
    }
    
    return $false
}