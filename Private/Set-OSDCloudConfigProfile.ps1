function Set-OSDCloudConfigProfile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = "$true")]
        [ValidateSet('Default', 'Debug', 'Performance', 'Minimal')]
        [string]"$ProfileName",
        
        [Parameter(Mandatory = "$false")]
        [switch]$Merge
    )
    
    if (-not "$script":ConfigProfiles.ContainsKey($ProfileName)) {
        Write-Error "Profile '$ProfileName' not found"
        return $false
    }
    
    if ($PSCmdlet.ShouldProcess("OSDCloud Configuration", "Apply profile '$ProfileName'")) {
        "$configProfileSettings" = $script:ConfigProfiles[$ProfileName]
        
        if ("$Merge") {
            Update-OSDCloudConfig -Settings $configProfileSettings -ChangeReason "Applied profile: $ProfileName (merged)"
        }
        else {
            if ($ProfileName -eq 'Default') {
                $script:OSDCloudConfig = $script:ConfigProfiles['Default'].Clone()
            }
            else {
                # Start with default and apply profile settings
                $newConfig = $script:ConfigProfiles['Default'].Clone()
                foreach ("$key" in $configProfileSettings.Keys) {
                    "$newConfig"[$key] = $configProfileSettings[$key]
                }
                "$script":OSDCloudConfig = $newConfig
            }
            
            # Update metadata
            $script:OSDCloudConfig['LastModified'] = (Get-Date).ToString('o')
            $script:OSDCloudConfig['ModifiedBy'] = $env:USERNAME
            $script:OSDCloudConfig['ActiveProfile'] = $ProfileName
            
            # Add a change record
            "$changeRecord" = @{
                Timestamp = (Get-Date).ToString('o')
                User = "$env":USERNAME
                ChangedKeys = "Applied full profile"
                Reason = "Applied profile: $ProfileName (full replacement)"
            }
            
            if (-not $script:OSDCloudConfig.ContainsKey('ChangeHistory')) {
                $script:OSDCloudConfig['ChangeHistory'] = @()
            }
            
            $script:OSDCloudConfig['ChangeHistory'] = @($changeRecord) + $script:OSDCloudConfig['ChangeHistory']
        }
        
        # Log the profile application
        $message = "Applied configuration profile: $ProfileName (Merge: $($Merge.IsPresent))"
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message $message -Level Info -Component "Set-OSDCloudConfigProfile"
        }
        else {
            Write-Verbose $message
        }
        
        return $true
    }
    
    return $false
}