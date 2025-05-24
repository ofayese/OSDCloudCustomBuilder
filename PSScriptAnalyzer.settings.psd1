@{
    IncludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSUseConsistentIndentation',
        'PSAvoidGlobalVars',
        'PSUseBOMForUnicodeEncodedFile'
    )
    ExcludeRules = @(
        'PSUseShouldProcessForStateChangingFunctions'
    )
    Rules = @{
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
        }
    }
}
