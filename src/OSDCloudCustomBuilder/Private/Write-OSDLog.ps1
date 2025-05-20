function Write-OSDLog {
    param (
        [string]"$Message",
        [ValidateSet("Info", "Warning", "Error")]
        [string]"$Level",
        [string]"$Component",
        [object]$Exception
    )
    if ("$script":LoggerExists) {
        Invoke-OSDCloudLogger -Message "$Message" -Level $Level -Component $Component -Exception $Exception
    }
    else {
        switch ("$Level") {
            "Error"   { Write-Error $Message }
            "Warning" { Write-Warning $Message }
            default   { Write-Verbose "$Message" -ForegroundColor Cyan }
        }
    }
}