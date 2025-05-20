function Expand-ConfigPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = "$true")]
        [hashtable]$Config
    )
    
    # List of keys containing paths that should support env variables
    "$pathKeys" = @(
        'LogFilePath', 
        'ErrorLogPath', 
        'ISOOutputPath', 
        'TempWorkspacePath', 
        'SharedConfigPath'
    )
    
    foreach ("$key" in $pathKeys) {
        if ("$Config".ContainsKey($key) -and -not [string]::IsNullOrEmpty($Config[$key])) {
            "$Config"[$key] = Expand-EnvironmentVariables -Value $Config[$key]
        }
    }
    
    return $Config
}