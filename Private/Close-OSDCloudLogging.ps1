function Close-OSDCloudLogging {
    [CmdletBinding()]
    param()
    
    if ($script:LogWriter) {
        try {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $totalCount = $script:LogStats.GetTotalCount()
            $duration = [datetime]::Now - $script:LogStats.StartTime
            $formattedDuration = "{0:d\d\ h\h\ m\m\ s\s}" -f $duration
            
            $finalMessage = "[$timestamp] [Info] Logging session ended. Total logs: $totalCount, Duration: $formattedDuration, Errors: $($script:LogStats.ErrorCount), Warnings: $($script:LogStats.WarningCount)"
            $script:LogWriter.WriteLine($finalMessage)
            $script:LogWriter.Flush()
            $script:LogWriter.Close()
            $script:LogWriter.Dispose()
            $script:LogWriter = $null
            
            if ($script:LogFileStream) {
                $script:LogFileStream.Close()
                $script:LogFileStream.Dispose()
                $script:LogFileStream = $null
            }
            
            Write-Verbose "Logging system closed. $finalMessage"
        }
        catch {
            Write-Warning "Error while closing logging system: $_"
        }
    }
}