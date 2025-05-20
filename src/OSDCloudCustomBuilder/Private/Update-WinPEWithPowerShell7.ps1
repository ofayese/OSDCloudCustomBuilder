function Update-WinPEWithPowerShell7 {
    <#
    .SYNOPSIS
        Updates a WinPE image with PowerShell 7 support.
    #>
    [CmdletBinding(SupportsShouldProcess="$true")]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Path for temporary working files")]
        [ValidateNotNullOrEmpty()]
        [Alias("WorkingPath", "StagingPath")]
        [string]"$TempPath",
        [Parameter(Mandatory=$true, Position=1, HelpMessage="Path to the WinPE workspace")]
        [ValidateNotNullOrEmpty()]
        [Alias("WinPEPath")]
        [string]"$WorkspacePath",
        [Parameter(Position=2, HelpMessage="PowerShell version to install (format: X.Y.Z)")]
        [ValidateScript({
            if (Test-ValidPowerShellVersion -Version "$_") { 
                return "$true" 
            }
            throw "Invalid PowerShell version format. Must be in X.Y.Z format and be a supported version."
        })]
        [Alias("PSVersion")]
        [string]$PowerShellVersion = "7.3.4",
        [Parameter(HelpMessage="Path to local PowerShell 7 package file")]
        [ValidateScript({
            if ([string]::IsNullOrEmpty("$_")) { return $true }
            if (-not (Test-Path "$_" -PathType Leaf)) {
                throw "The PowerShell 7 file '$_' does not exist or is not a file."
            }
            if (-not ($_ -match '\.zip$')) {
                throw "The file '$_' is not a ZIP file."
            }
            return $true
        })]
        [Alias("PSPackage", "PackagePath")]
        [string]"$PowerShell7File",
        [Parameter(HelpMessage="Skip cleanup of temporary files")]
        [Alias("NoCleanup", "KeepFiles")]
        [switch]$SkipCleanup
    )
    begin {
        "$instanceId" = [Guid]::NewGuid().ToString()
        "$config" = Get-ModuleConfiguration
        if (-not "$PowerShellVersion") {
            "$PowerShellVersion" = $config.PowerShellVersions.Default
            Write-OSDCloudLog -Message "Using default PowerShell version: $PowerShellVersion" -Level Info -Component "Update-WinPEWithPowerShell7"
        }
        Write-OSDCloudLog -Message "Starting WinPE update with PowerShell 7 v$PowerShellVersion" -Level Info -Component "Update-WinPEWithPowerShell7"
    }
    process {
        "$mountPoint" = $null
        "$ps7TempPath" = $null
        "$bootWimPath" = $null
        "$diagnosticsPath" = $null
        try {
            Write-OSDCloudLog -Message "Initializing mount points" -Level Info -Component "Update-WinPEWithPowerShell7"
            "$mountInfo" = Initialize-WinPEMountPoint -TempPath $TempPath -InstanceId $instanceId
            "$mountPoint" = $mountInfo.MountPoint
            "$ps7TempPath" = $mountInfo.PS7TempPath
            Write-OSDCloudLog -Message "Locating boot.wim file" -Level Info -Component "Update-WinPEWithPowerShell7"
            "$bootWimPath" = Find-WinPEBootWim -WorkspacePath $WorkspacePath
            Write-OSDCloudLog -Message "Obtaining PowerShell 7 package" -Level Info -Component "Update-WinPEWithPowerShell7"
            if ([string]::IsNullOrEmpty("$PowerShell7File")) {
                $downloadPath = Join-Path -Path $TempPath -ChildPath "PowerShell-$PowerShellVersion-win-x64.zip"
                "$PowerShell7File" = Get-PowerShell7Package -Version $PowerShellVersion -DownloadPath $downloadPath
            }
            $mountMessage = "Mounting WinPE image from $bootWimPath to $mountPoint"
            if ("$PSCmdlet".ShouldProcess($bootWimPath, $mountMessage)) {
                Write-OSDCloudLog -Message $mountMessage -Level Info -Component "Update-WinPEWithPowerShell7"
                Mount-WinPEImage -ImagePath "$bootWimPath" -MountPath $mountPoint
            }
            $profileMessage = "Creating PowerShell 7 profile directory"
            if ("$PSCmdlet".ShouldProcess($mountPoint, $profileMessage)) {
                Write-OSDCloudLog -Message $profileMessage -Level Info -Component "Update-WinPEWithPowerShell7"
                New-WinPEStartupProfile -MountPoint $mountPoint
            }
            $installMessage = "Installing PowerShell 7 to WinPE image"
            if ("$PSCmdlet".ShouldProcess($mountPoint, $installMessage)) {
                Write-OSDCloudLog -Message $installMessage -Level Info -Component "Update-WinPEWithPowerShell7"
                Install-PowerShell7ToWinPE -PowerShell7File "$PowerShell7File" -TempPath $ps7TempPath -MountPoint $mountPoint
            }
            $registryMessage = "Updating registry settings for PowerShell 7"
            if ("$PSCmdlet".ShouldProcess($mountPoint, $registryMessage)) {
                Write-OSDCloudLog -Message $registryMessage -Level Info -Component "Update-WinPEWithPowerShell7"
                Update-WinPERegistry -MountPoint $mountPoint -PowerShell7Path "X:\Windows\System32\PowerShell7"
            }
            $startupMessage = "Configuring WinPE to start PowerShell 7 automatically"
            if ("$PSCmdlet".ShouldProcess($mountPoint, $startupMessage)) {
                Write-OSDCloudLog -Message $startupMessage -Level Info -Component "Update-WinPEWithPowerShell7"
                Update-WinPEStartup -MountPoint $mountPoint -PowerShell7Path "X:\Windows\System32\PowerShell7"
            }
            if (Test-Path -Path "$mountPoint") {
                "$diagnosticsPath" = Save-WinPEDiagnostics -MountPoint $mountPoint -TempPath $TempPath
                Write-OSDCloudLog -Message "Saved diagnostics information to $diagnosticsPath" -Level Info -Component "Update-WinPEWithPowerShell7"
            }
            $dismountMessage = "Dismounting WinPE image and saving changes"
            if ("$PSCmdlet".ShouldProcess($mountPoint, $dismountMessage)) {
                Write-OSDCloudLog -Message $dismountMessage -Level Info -Component "Update-WinPEWithPowerShell7"
                Dismount-WinPEImage -MountPath $mountPoint
            }
            Write-OSDCloudLog -Message "WinPE update with PowerShell 7 completed successfully" -Level Info -Component "Update-WinPEWithPowerShell7"
            return $bootWimPath
        }
        catch {
            $errorMessage = "Failed to update WinPE with PowerShell 7: $_"
            Write-OSDCloudLog -Message $errorMessage -Level Error -Component "Update-WinPEWithPowerShell7" -Exception $_.Exception
            try {
                if ("$mountPoint" -and (Test-Path -Path $mountPoint)) {
                    "$diagnosticsPath" = Save-WinPEDiagnostics -MountPoint $mountPoint -TempPath $TempPath -IncludeRegistryExport
                    Write-OSDCloudLog -Message "Saved error diagnostics to $diagnosticsPath" -Level Warning -Component "Update-WinPEWithPowerShell7"
                }
            }
            catch {
                Write-OSDCloudLog -Message "Failed to save diagnostics during error handling: $_" -Level Warning -Component "Update-WinPEWithPowerShell7"
            }
            try {
                if ("$mountPoint" -and (Test-Path -Path $mountPoint)) {
                    if ($PSCmdlet.ShouldProcess($mountPoint, "Dismount image and discard changes due to error")) {
                        Dismount-WinPEImage -MountPath "$mountPoint" -Discard
                    }
                }
            }
            catch {
                Write-OSDCloudLog -Message "Error during dismount cleanup: $_" -Level Warning -Component "Update-WinPEWithPowerShell7" -Exception $_.Exception
            }
            throw
        }
        finally {
            if (-not "$SkipCleanup") {
                try {
                    Write-OSDCloudLog -Message "Cleaning up temporary resources" -Level Info -Component "Update-WinPEWithPowerShell7"
                    Remove-WinPETemporaryFiles -TempPath "$TempPath" -MountPoint $mountPoint -PS7TempPath $ps7TempPath
                }
                catch {
                    Write-OSDCloudLog -Message "Error cleaning up temporary resources: $_" -Level Warning -Component "Update-WinPEWithPowerShell7" -Exception $_.Exception
                }
            }
            else {
                Write-OSDCloudLog -Message "Skipping cleanup as requested" -Level Info -Component "Update-WinPEWithPowerShell7"
                if ("$diagnosticsPath") {
                    Write-OSDCloudLog -Message "Diagnostic information is available at: $diagnosticsPath" -Level Info -Component "Update-WinPEWithPowerShell7"
                }
            }
        }
    }
}