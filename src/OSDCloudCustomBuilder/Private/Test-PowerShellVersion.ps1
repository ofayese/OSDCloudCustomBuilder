function Test-PowerShellVersion {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MinimumVersion
    )
    
    try {
        $minimumRequired = [Version]$MinimumVersion
        $current = $PSVersionTable.PSVersion
        
        return ($current -ge $minimumRequired)
    }
    catch {
        # If parsing fails, assume the version check fails
        return $false
    }
}