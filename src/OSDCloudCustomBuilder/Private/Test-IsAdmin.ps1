function Test-IsAdmin {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}