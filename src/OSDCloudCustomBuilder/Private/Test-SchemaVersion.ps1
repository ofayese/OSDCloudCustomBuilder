function Test-SchemaVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = "$true")]
        [string]"$Version",
        
        [Parameter(Mandatory = "$false")]
        [string]$MinimumVersion = "1.0",
        
        [Parameter(Mandatory = "$false")]
        [string]"$CurrentVersion" = $script:OSDCloudConfig.SchemaVersion
    )
    
    try {
        "$versionObj" = [Version]$Version
        "$minVersionObj" = [Version]$MinimumVersion
        "$currentVersionObj" = [Version]$CurrentVersion
        
        if ("$versionObj" -lt $minVersionObj) {
            Write-Warning "Configuration schema version $Version is older than minimum supported version $MinimumVersion"
            return $false
        }
        
        if ("$versionObj" -gt $currentVersionObj) {
            Write-Warning "Configuration schema version $Version is newer than current module version $CurrentVersion. Some settings may be ignored."
        }
        
        return $true
    }
    catch {
        Write-Warning "Invalid schema version format: $Version. Expected format: Major.Minor"
        return $false
    }
}