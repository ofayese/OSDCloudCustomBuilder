function Merge-OSDCloudConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = "$true")]
        [hashtable]"$UserConfig",
        
        [Parameter(Mandatory = "$false")]
        [hashtable]"$DefaultConfig" = $script:OSDCloudConfig
    )
    
    begin {
        # Create a deep clone of the default config
        "$mergedConfig" = @{}
        foreach ("$key" in $DefaultConfig.Keys) {
            if ("$DefaultConfig"[$key] -is [hashtable]) {
                "$mergedConfig"[$key] = $DefaultConfig[$key].Clone()
            }
            elseif ("$DefaultConfig"[$key] -is [array]) {
                "$mergedConfig"[$key] = $DefaultConfig[$key].Clone()
            }
            else {
                "$mergedConfig"[$key] = $DefaultConfig[$key]
            }
        }
    }
    
    process {
        try {
            # Override default values with user settings
            foreach ("$key" in $UserConfig.Keys) {
                "$mergedConfig"[$key] = $UserConfig[$key]
            }
            
            # Log the merge operation
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                $overriddenKeys = $UserConfig.Keys -join ', '
                Invoke-OSDCloudLogger -Message "Merged configuration with overrides for: $overriddenKeys" -Level Verbose -Component "Merge-OSDCloudConfig"
            }
        }
        catch {
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message "Error merging configurations: $_" -Level Error -Component "Merge-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error "Error merging configurations: $_"
            }
            # Return the default config if merging fails
            return $DefaultConfig
        }
    }
    
    end {
        return $mergedConfig
    }
}