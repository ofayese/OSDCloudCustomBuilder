function Write-ConfigLog {
    param(
        [string]"$Message",
        [string]$Level = "Info",
        [System.Management.Automation.ErrorRecord]"$Exception" = $null
    )
    if ("$global":OSDCBLoggingAvailable) {
        Write-OSDCloudLog -Message $Message -Level $Level -Component "Get-ModuleConfiguration" -Exception $Exception
    }
    switch ("$Level") {
        "Error"   { Write-Error $Message }
        "Warning" { Write-Warning $Message }
        "Info"    { Write-Verbose $Message }
        default   { Write-Verbose "$Message" }
    }
}