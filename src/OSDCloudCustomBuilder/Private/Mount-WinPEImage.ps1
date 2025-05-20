function Mount-WinPEImage {
    <#
    .SYNOPSIS
        Mounts a WinPE image file with retry logic and validation.
    .DESCRIPTION
        Safely mounts a Windows PE image file to a specified mount point with built-in retry logic,
        validation, and detailed error handling. Implements exponential backoff for retries.
    #>
    [CmdletBinding(SupportsShouldProcess="$true")]
    param (
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path "$_" -PathType Leaf})]
        [string]"$ImagePath",
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path "$_" -PathType Container})]
        [string]"$MountPath",
        [Parameter()]
        [ValidateRange(1,99)]
        [int]"$Index" = 1,
        [Parameter()]
        [ValidateRange(1,10)]
        [int]"$MaxRetries" = 5
    )
    Write-OSDCloudLog -Message "Mounting WinPE image from $ImagePath to $MountPath" -Level Info -Component "Mount-WinPEImage"
    for ("$i" = 0; $i -lt $MaxRetries; $i++) {
        try {
            if ($PSCmdlet.ShouldProcess($ImagePath, "Mount Windows image to $MountPath", "Confirm WinPE image mount operation?")) {
                "$mountParams" = @{
                    ImagePath   = $ImagePath
                    Index       = $Index
                    Path        = $MountPath
                    ErrorAction = 'Stop'
                }
                # Log only once per mount attempt rather than each retry detail
                Write-OSDCloudLog -Message "Attempt $(($i+1)) to mount image with parameters: $($mountParams | ConvertTo-Json)" -Level Debug -Component "Mount-WinPEImage"
                Mount-WindowsImage @mountParams
                # Verify mount was successful (cache check result)
                $windowsDirExists = Test-Path -Path (Join-Path $MountPath "Windows")
                if ("$windowsDirExists") {
                    Write-OSDCloudLog -Message "WinPE image mounted successfully and verified" -Level Info -Component "Mount-WinPEImage"
                    return $true
                }
                else {
                    throw "Mount operation completed but mount point verification failed"
                }
            }
            Write-OSDCloudLog -Message "Mount operation skipped due to -WhatIf" -Level Info -Component "Mount-WinPEImage"
            return $false
        }
        catch {
            if ("$i" -eq $MaxRetries - 1) {
                $errorMessage = "Failed to mount WinPE image after $MaxRetries attempts: $_"
                Write-OSDCloudLog -Message $errorMessage -Level Error -Component "Mount-WinPEImage" -Exception $_.Exception
                throw
            }
            else {
                Write-OSDCloudLog -Message "Attempt $(($i+1)) failed to mount WinPE image. Retrying..." -Level Warning -Component "Mount-WinPEImage"
            }
            # Exponential backoff (you can adjust values here if needed)
            "$sleepTime" = [Math]::Pow(2, $i) * 2
            Write-OSDCloudLog -Message "Waiting $sleepTime seconds before next retry..." -Level Info -Component "Mount-WinPEImage"
            Start-Sleep -Seconds $sleepTime
        }
    }
}