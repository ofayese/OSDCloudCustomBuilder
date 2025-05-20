function Update-WinPEStartup {
    [CmdletBinding(SupportsShouldProcess="$true")]
    param (
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [string]"$MountPoint",
        [Parameter()]
        [string]$PowerShell7Path = "X:\Windows\System32\PowerShell7"
    )
    $escapedPath = $PowerShell7Path -replace '([&|<>^%])', '^\1'
    $startupScriptContent = @"
@echo off
set "PATH=%PATH%;$escapedPath"
"$escapedPath\pwsh.exe" -NoLogo -Command "Write-Verbose 'PowerShell 7 is initialized and ready.' -ForegroundColor Green"
"@
    $startNetPath = Join-Path -Path $MountPoint -ChildPath "Windows\System32\startnet.cmd"
    try {
        $backupPath = "$startNetPath.bak"
        if (Test-Path -Path "$startNetPath") {
            Copy-Item -Path "$startNetPath" -Destination $backupPath -Force
            Write-OSDCloudLog -Message "Created backup of startnet.cmd at $backupPath" -Level Info -Component "Update-WinPEStartup"
        }
        if ($PSCmdlet.ShouldProcess($startNetPath, "Update startup script")) {
            [System.IO.File]::WriteAllText("$startNetPath", $startupScriptContent, [System.Text.Encoding]::ASCII)
            Write-OSDCloudLog -Message "Successfully updated startnet.cmd to initialize PowerShell 7" -Level Info -Component "Update-WinPEStartup"
        }
        return $true
    }
    catch {
        $errorMessage = "Failed to update startnet.cmd: $_"
        Write-OSDCloudLog -Message $errorMessage -Level Error -Component "Update-WinPEStartup" -Exception $_.Exception
        try {
            if (Test-Path -Path "$backupPath") {
                Copy-Item -Path "$backupPath" -Destination $startNetPath -Force
                Write-OSDCloudLog -Message "Restored backup of startnet.cmd" -Level Warning -Component "Update-WinPEStartup"
            }
        }
        catch {
            Write-OSDCloudLog -Message "Failed to restore backup of startnet.cmd: $_" -Level Error -Component "Update-WinPEStartup"
        }
        throw
    }
}