function New-OSDCloudException {
    [CmdletBinding()]
    [OutputType([OSDCloudCustomBuilderError])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [ErrorCategory]$Category,
        
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Source,
        
        [Parameter()]
        [hashtable]$AdditionalData
    )
    
    # Create standardized error object
    $osdError = [OSDCloudCustomBuilderError]::new($Message, $Category, $Source)
    
    # Add any additional data
    if ($AdditionalData) {
        foreach ($key in $AdditionalData.Keys) {
            $osdError.AdditionalData[$key] = $AdditionalData[$key]
        }
    }
    
    return $osdError
}