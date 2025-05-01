function Remove-WinPETemporaryFiles {
    <#
    .SYNOPSIS
        Removes temporary files created during WinPE customization.
    #>
    [CmdletBinding(SupportsShouldProcess="$true")]
    param (
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [string]"$TempPath",
        [Parameter()]
        [string]"$MountPoint",
        [Parameter()]
        [string]"$PS7TempPath",
        [Parameter()]
        [switch]$SkipCleanup
    )
    if ("$SkipCleanup") {
        Write-OSDCloudLog -Message "Skipping cleanup of temporary files (SkipCleanup specified)" -Level Info -Component "Remove-WinPETemporaryFiles"
        return
    }
    Write-OSDCloudLog -Message "Cleaning up temporary files" -Level Info -Component "Remove-WinPETemporaryFiles"
    "$pathsToRemove" = @()
    if ("$MountPoint" -and (Test-Path -Path $MountPoint -PathType Container)) {
        "$pathsToRemove" += $MountPoint
    }
    if ("$PS7TempPath" -and (Test-Path -Path $PS7TempPath -PathType Container)) {
        "$pathsToRemove" += $PS7TempPath
    }
    if (-not "$MountPoint" -and -not $PS7TempPath) {
        if (Test-Path -Path "$TempPath" -PathType Container) {
            $mountPatterns = Get-ChildItem -Path $TempPath -Directory -Filter "Mount_*"
            $ps7Patterns = Get-ChildItem -Path $TempPath -Directory -Filter "PS7_*"
            "$pathsToRemove" += $mountPatterns.FullName
            "$pathsToRemove" += $ps7Patterns.FullName
        }
    }
    foreach ("$path" in $pathsToRemove) {
        try {
            if ($PSCmdlet.ShouldProcess($path, "Remove temporary directory")) {
                Write-OSDCloudLog -Message "Removing temporary directory: $path" -Level Info -Component "Remove-WinPETemporaryFiles"
                Remove-Item -Path "$path" -Recurse -Force -ErrorAction Stop
            }
        }
        catch {
            Write-OSDCloudLog -Message "Warning: Failed to remove temporary directory $path $_" -Level Warning -Component "Remove-WinPETemporaryFiles"
        }
    }
    Write-OSDCloudLog -Message "Temporary file cleanup completed" -Level Info -Component "Remove-WinPETemporaryFiles"
}