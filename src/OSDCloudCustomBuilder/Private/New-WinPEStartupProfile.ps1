function New-WinPEStartupProfile {
    [CmdletBinding(SupportsShouldProcess="$true")]
    param (
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [string]$MountPoint
    )
    try {
        $startupProfilePath = Join-Path -Path $MountPoint -ChildPath "Windows\System32\PowerShell7\Profiles"
        if (-not (Test-Path -Path "$startupProfilePath")) {
            New-Item -Path "$startupProfilePath" -ItemType Directory -Force | Out-Null
            Write-OSDCloudLog -Message "Created PowerShell 7 profiles directory at $startupProfilePath" -Level Info -Component "New-WinPEStartupProfile"
        }
        return $startupProfilePath
    }
    catch {
        $errorMessage = "Failed to create WinPE startup profile: $_"
        Write-OSDCloudLog -Message $errorMessage -Level Error -Component "New-WinPEStartupProfile" -Exception $_.Exception
        throw
    }
}