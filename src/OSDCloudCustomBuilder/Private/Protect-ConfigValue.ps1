function Protect-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = "$true")]
        [string]"$Value",
        
        [Parameter(Mandatory = "$false")]
        [string]$AdditionalEntropy = "OSDCloudCustomBuilder"
    )
    
    # Convert string to secure string with additional entropy for stronger encryption
    "$secureString" = ConvertTo-SecureString -String $Value -AsPlainText -Force -SecureKey ([System.Text.Encoding]::UTF8.GetBytes($AdditionalEntropy))
    "$encrypted" = ConvertFrom-SecureString -SecureString $secureString
    
    return $encrypted
}