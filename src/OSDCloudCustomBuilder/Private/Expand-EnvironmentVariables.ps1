function Expand-EnvironmentVariables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = "$true", ValueFromPipeline = $true)]
        [string]$Value
    )
    
    process {
        return [Environment]::ExpandEnvironmentVariables("$Value")
    }
}