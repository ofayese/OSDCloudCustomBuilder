<#
.SYNOPSIS
    Protects sensitive configuration values through DPAPI encryption.
.DESCRIPTION
    Encrypts sensitive configuration values using Windows Data Protection API (DPAPI) to protect them when stored on disk.
    The encryption is Windows user account specific and provides secure storage without requiring additional keys.
.PARAMETER Value
    The sensitive string value to encrypt.
.PARAMETER Scope
    The scope of the encryption (CurrentUser or LocalMachine).
.PARAMETER AdditionalEntropy
    Optional additional entropy for stronger encryption.
.EXAMPLE
    $encryptedValue = Protect-ConfigValue -Value "p@ssw0rd"
.EXAMPLE
    $encryptedValue = Protect-ConfigValue -Value "ApiKey123" -Scope "LocalMachine"
.NOTES
    This function uses Windows Data Protection API (DPAPI) for secure encryption.
    The encrypted data can only be decrypted by the same user account (CurrentUser scope)
    or machine (LocalMachine scope) that encrypted it.
#>
function Protect-ConfigValue {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$Scope = 'CurrentUser',

        [Parameter(Mandatory = $false)]
        [string]$AdditionalEntropy = "OSDCloudCustomBuilder"
    )

    process {
        try {
            # Handle empty or null values
            if ([string]::IsNullOrEmpty($Value)) {
                return @{
                    EncryptedValue = ""
                    Scope = $Scope
                    Type = "String"
                    Entropy = $false
                }
            }

            # Convert string to bytes
            $valueBytes = [System.Text.Encoding]::UTF8.GetBytes($Value)

            # Prepare entropy if provided
            $entropyBytes = $null
            if (-not [string]::IsNullOrEmpty($AdditionalEntropy)) {
                $entropyBytes = [System.Text.Encoding]::UTF8.GetBytes($AdditionalEntropy)
            }

            # Encrypt using DPAPI
            $protectionScope = if ($Scope -eq 'CurrentUser') {
                [System.Security.Cryptography.DataProtectionScope]::CurrentUser
            } else {
                [System.Security.Cryptography.DataProtectionScope]::LocalMachine
            }

            $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect(
                $valueBytes,
                $entropyBytes,
                $protectionScope
            )

            # Convert to Base64 for storage
            $encryptedValue = [Convert]::ToBase64String($encryptedBytes)

            # Return structured result
            return @{
                EncryptedValue = $encryptedValue
                Scope = $Scope
                Type = "String"
                Entropy = (-not [string]::IsNullOrEmpty($AdditionalEntropy))
                Timestamp = (Get-Date).ToString('o')
            }
        }
        catch {
            Write-Error "Failed to encrypt value: $_"
            throw $_
        }
    }
}
