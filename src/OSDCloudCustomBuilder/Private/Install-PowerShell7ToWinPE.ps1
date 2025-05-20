function Install-PowerShell7ToWinPE {
    [CmdletBinding(SupportsShouldProcess="$true")]
    param (
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path "$_" -PathType Leaf})]
        [string]"$PowerShell7File",
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [string]"$TempPath",
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [string]$MountPoint
    )
    $pwsh7Destination = Join-Path -Path $MountPoint -ChildPath "Windows\System32\PowerShell7"
    Write-OSDCloudLog -Message "Installing PowerShell 7 to WinPE at $pwsh7Destination" -Level Info -Component "Install-PowerShell7ToWinPE"
    if (-not (Test-Path -Path "$pwsh7Destination")) {
        New-Item -Path "$pwsh7Destination" -ItemType Directory -Force | Out-Null
    }
    try {
        Write-OSDCloudLog -Message "Extracting PowerShell 7 from $PowerShell7File" -Level Info -Component "Install-PowerShell7ToWinPE"
        if ($PSCmdlet.ShouldProcess($PowerShell7File, "Extract to $pwsh7Destination")) {
            Expand-Archive -Path "$PowerShell7File" -DestinationPath $pwsh7Destination -Force
            # Verify extraction
            $pwshExe = Join-Path -Path $pwsh7Destination -ChildPath "pwsh.exe"
            if (-not (Test-Path -Path "$pwshExe")) {
                throw "PowerShell 7 extraction failed - pwsh.exe not found in destination"
            }
            Write-OSDCloudLog -Message "PowerShell 7 successfully extracted to WinPE" -Level Info -Component "Install-PowerShell7ToWinPE"
        }
    }
    catch {
        $errorMessage = "Failed to install PowerShell 7 to WinPE: $_"
        Write-OSDCloudLog -Message $errorMessage -Level Error -Component "Install-PowerShell7ToWinPE" -Exception $_.Exception
        throw
    }
}