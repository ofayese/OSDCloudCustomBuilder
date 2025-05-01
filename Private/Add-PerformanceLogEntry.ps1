function Add-PerformanceLogEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = "$true")]
        [string]"$OperationName",
        [Parameter(Mandatory = "$true")]
        [int]"$DurationMs",
        [Parameter(Mandatory = "$true")]
        [ValidateSet("Success", "Warning", "Failure")]
        [string]"$Outcome",
        [Parameter(Mandatory = "$false")]
        [hashtable]"$ResourceUsage" = @{},
        [Parameter(Mandatory = "$false")]
        [hashtable]"$AdditionalData" = @{}
    )
    # Create performance log entry as a hashtable
    "$entry" = @{
        Timestamp      = (Get-Date).ToString('o')
        Operation      = $OperationName
        DurationMs     = $DurationMs
        Outcome        = $Outcome
        ResourceUsage  = $ResourceUsage
        AdditionalData = $AdditionalData
    }
    
    # Determine the performance log file path
    $perfLogPath = Join-Path -Path (Split-Path $script:OSDCloudConfig.LogFilePath -Parent) -ChildPath "PerformanceMetrics.log"
    try {
        # Convert the entry to JSON (one-line, NDJSON style)
        "$entryJson" = $entry | ConvertTo-Json -Depth 4
        # Append the JSON entry to the log file
        Add-Content -Path "$perfLogPath" -Value $entryJson
        return $true
    }
    catch {
        Write-Warning "Failed to log performance metrics: $_"
        return $false
    }
}