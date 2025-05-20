function Write-OSDCloudError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Message,
        
        [Parameter(Mandatory = $true, Position = 2)]
        [ErrorCategory]$Category,
        
        [Parameter(Mandatory = $true, Position = 3)]
        [string]$Source,
        
        [Parameter()]
        [switch]$SuppressError,
        
        [Parameter()]
        [hashtable]$AdditionalData
    )
    
    # Create standardized error object
    $osdError = [OSDCloudCustomBuilderError]::new($Message, $Category, $Source, $ErrorRecord)
    
    # Add any additional data
    if ($AdditionalData) {
        foreach ($key in $AdditionalData.Keys) {
            $osdError.AdditionalData[$key] = $AdditionalData[$key]
        }
    }
    
    # Add to collection for telemetry
    $script:ErrorCollection.Add($osdError)
    
    # Log the error
    $errorMessage = $osdError.ToString()
    
    # Check if OSDCloud logger exists
    $loggerExists = Get-Command -Name Write-OSDCloudLog -ErrorAction SilentlyContinue
    if ($loggerExists) {
        Write-OSDCloudLog -Message $errorMessage -Level Error
    }
    else {
        Write-Error $errorMessage
    }
    
    # Configure error handling behavior based on module config
    $errorConfig = Get-ModuleConfiguration -Setting "ErrorHandling" -ErrorAction SilentlyContinue
    
    $continueOnError = $false
    if ($errorConfig -and $errorConfig.ContainsKey("ContinueOnError")) {
        $continueOnError = $errorConfig.ContinueOnError
    }
    
    # If not suppressing and configuration doesn't specify to continue, re-throw the error
    if (-not $SuppressError -and -not $continueOnError) {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new($errorMessage, $ErrorRecord.Exception),
                "OSDCloudCustomBuilder_$($Category)",
                [System.Management.Automation.ErrorCategory]::FromStdErr,
                $Source
            )
        )
    }
}