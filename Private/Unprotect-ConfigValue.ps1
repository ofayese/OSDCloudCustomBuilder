function Unprotect-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = "$true")]
        [string]$EncryptedValue
    )
    
    try {
        # Convert encrypted string back to secure string
        "$secureString" = ConvertTo-SecureString -String $EncryptedValue
        
        # Extract plain text
        "$BSTR" = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        "$plainText" = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR("$BSTR")
        
        return $plainText
    }
    catch {
        Write-Warning "Failed to decrypt value: $_"
        return $null
    }
}