function ApplyEnvironmentOverrides {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    # Use Get-ChildItem with a wildcard filter instead of Where-Object.
    $envVars = Get-ChildItem -Path Env:OSDCB_*
    foreach ($var in $envVars) {
        $parts = $var.Name -split '_', 3
        if ($parts.Count -ge 3) {
            $section = $parts[1]
            $key = $parts[2]
            if ($Config.ContainsKey($section) -and $Config[$section] -is [hashtable]) {
                $value = $var.Value
                if ($value -eq "true" -or $value -eq "false") {
                    $value = [bool]::Parse($value)
                }
                elseif ($value -match "^\d+$") {
                    $value = [int]::Parse($value)
                }
                elseif ($value -match "^\d+\.\d+$") {
                    $value = [double]::Parse($value)
                }
                $Config[$section][$key] = $value
                Write-Verbose "Applied environment override: $section.$key = $value"
            }
        }
    }
}