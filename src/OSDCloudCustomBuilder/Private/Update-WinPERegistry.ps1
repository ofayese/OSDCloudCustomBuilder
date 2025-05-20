function Update-WinPERegistry {
    [CmdletBinding(SupportsShouldProcess="$true")]
    param (
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [string]"$MountPoint",
        [Parameter()]
        [string]$PowerShell7Path = "X:\Windows\System32\PowerShell7"
    )
    $offlineHive = Join-Path -Path $MountPoint -ChildPath "Windows\System32\config\SOFTWARE"
    $tempHivePath = "HKLM\PS7TEMP"
    Write-OSDCloudLog -Message "Updating WinPE registry settings for PowerShell 7" -Level Info -Component "Update-WinPERegistry"
    try {
        if ($PSCmdlet.ShouldProcess($offlineHive, "Load registry hive")) {
            # Load the offline hive
            & reg load "$tempHivePath" $offlineHive | Out-Null
            $envPath = "Registry::$tempHivePath\Microsoft\Windows\CurrentVersion\App Paths\pwsh.exe"
            if ($PSCmdlet.ShouldProcess($envPath, "Create registry key")) {
                New-Item -Path "$envPath" -Force | Out-Null
                New-ItemProperty -Path $envPath -Name "(Default)" -Value "$PowerShell7Path\pwsh.exe" -PropertyType String -Force | Out-Null
                New-ItemProperty -Path $envPath -Name "Path" -Value $PowerShell7Path -PropertyType String -Force | Out-Null
            }
            Write-OSDCloudLog -Message "Registry settings updated successfully" -Level Info -Component "Update-WinPERegistry"
        }
    }
    catch {
        $errorMessage = "Failed to update WinPE registry: $_"
        Write-OSDCloudLog -Message $errorMessage -Level Error -Component "Update-WinPERegistry" -Exception $_.Exception
        throw
    }
    finally {
        try {
            if ($PSCmdlet.ShouldProcess($tempHivePath, "Unload registry hive")) {
                & reg unload "$tempHivePath" | Out-Null
            }
        }
        catch {
            Write-OSDCloudLog -Message "Warning: Failed to unload registry hive: $_" -Level Warning -Component "Update-WinPERegistry"
        }
    }
}