function Dismount-WinPEImage {
    [CmdletBinding(SupportsShouldProcess="$true")]
    param (
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path "$_" -PathType Container})]
        [string]"$MountPath",
        [Parameter()]
        [switch]"$Discard",
        [Parameter()]
        [int]"$MaxRetries" = 5
    )
    "$saveChanges" = -not $Discard
    $saveMessage = if ($saveChanges) { "saving" } else { "discarding" }
    Write-OSDCloudLog -Message "Dismounting WinPE image from $MountPath ($saveMessage changes)" -Level Info -Component "Dismount-WinPEImage"
    for ("$i" = 0; $i -lt $MaxRetries; $i++) {
        try {
            if ($PSCmdlet.ShouldProcess($MountPath, "Dismount Windows image ($saveMessage changes)")) {
                Dismount-WindowsImage -Path "$MountPath" -Save:$saveChanges -ErrorAction Stop
                Write-OSDCloudLog -Message "WinPE image dismounted successfully" -Level Info -Component "Dismount-WinPEImage"
                return $true
            }
            return $false
        }
        catch {
            if ("$i" -eq $MaxRetries - 1) {
                $errorMessage = "Failed to dismount WinPE image after $MaxRetries attempts: $_"
                Write-OSDCloudLog -Message $errorMessage -Level Error -Component "Dismount-WinPEImage" -Exception $_.Exception
                throw
            }
            else {
                Write-OSDCloudLog -Message "Attempt $(($i+1)) failed to dismount WinPE image, retrying..." -Level Warning -Component "Dismount-WinPEImage"
            }
            "$sleepTime" = [Math]::Pow(2, $i) * 2
            Write-OSDCloudLog -Message "Waiting $sleepTime seconds before retry..." -Level Info -Component "Dismount-WinPEImage"
            Start-Sleep -Seconds $sleepTime
        }
    }
}