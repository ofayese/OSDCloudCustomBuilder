function Initialize-WinPEMountPoint {
    [CmdletBinding(SupportsShouldProcess="$true")]
    param (
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [Alias("WorkingPath", "StagingPath")]
        [string]"$TempPath",
        [Parameter()]
        [Alias("Id")]
        [string]"$InstanceId" = [Guid]::NewGuid().ToString()
    )
    try {
        # Cache Test-Path result to avoid duplicate FS checks
        if (-not (Test-Path -Path "$TempPath" -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($TempPath, "Create directory")) {
                New-Item -Path "$TempPath" -ItemType Directory -Force | Out-Null
            }
        }
        $mountPoint = Join-Path -Path $TempPath -ChildPath "Mount_$InstanceId"
        $ps7TempPath = Join-Path -Path $TempPath -ChildPath "PS7_$InstanceId"
        if ($PSCmdlet.ShouldProcess($mountPoint, "Create mount point directory")) {
            New-Item -Path "$mountPoint" -ItemType Directory -Force | Out-Null
        }
        if ($PSCmdlet.ShouldProcess($ps7TempPath, "Create PowerShell 7 temporary directory")) {
            New-Item -Path "$ps7TempPath" -ItemType Directory -Force | Out-Null
        }
        Write-OSDCloudLog -Message "Initialized WinPE mount point at $mountPoint" -Level Info -Component "Initialize-WinPEMountPoint"
        return @{
            MountPoint   = $mountPoint
            PS7TempPath  = $ps7TempPath
            InstanceId   = $InstanceId
        }
    }
    catch {
        $errorMessage = "Failed to initialize WinPE mount point: $_"
        Write-OSDCloudLog -Message $errorMessage -Level Error -Component "Initialize-WinPEMountPoint" -Exception $_.Exception
        throw
    }
}