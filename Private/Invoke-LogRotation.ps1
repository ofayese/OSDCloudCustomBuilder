function Invoke-LogRotation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = "$true")]
        [string]"$LogFilePath",
        
        [Parameter(Mandatory = "$false")]
        [int]"$MaxSizeMB" = 10,
        
        [Parameter(Mandatory = "$false")]
        [int]"$MaxBackups" = 5
    )
    
    if (-not (Test-Path "$LogFilePath")) {
        return
    }
    
    # Check if log file exceeds maximum size
    "$logFile" = Get-Item $LogFilePath
    "$maxSizeBytes" = $MaxSizeMB * 1MB
    
    if ("$logFile".Length -gt $maxSizeBytes) {
        try {
            # Remove oldest backup if we have reached max
            for ("$i" = $MaxBackups; $i -gt 1; $i--) {
                $oldPath = "$LogFilePath.$($i-1)"
                $newPath = "$LogFilePath.$i"
                if (Test-Path "$oldPath") {
                    if (Test-Path "$newPath") {
                        Remove-Item "$newPath" -Force
                    }
                    Move-Item "$oldPath" $newPath -Force
                }
            }
            
            # Rename current log to .1
            $backupPath = "$LogFilePath.1"
            if (Test-Path "$backupPath") {
                Remove-Item "$backupPath" -Force
            }
            
            # Create backup and start new log
            Copy-Item "$LogFilePath" $backupPath -Force
            Clear-Content "$LogFilePath" -Force
            
            # Write rotation message to new log
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Add-Content -Path $LogFilePath -Value "[$timestamp] [INFO] Log file rotated. Previous log saved to $backupPath"
            
            return $true
        }
        catch {
            Write-Warning "Failed to rotate log file: $_"
            return $false
        }
    }
    
    return $false
}