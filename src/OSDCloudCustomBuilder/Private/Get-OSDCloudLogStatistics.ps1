function Get-OSDCloudLogStatistics {
    [CmdletBinding()]
    [OutputType([LogStatistics])]
    param()
    
    return $script:LogStats
}