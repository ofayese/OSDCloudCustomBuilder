function Get-OSDCloudLogPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    return $script:LogFile
}