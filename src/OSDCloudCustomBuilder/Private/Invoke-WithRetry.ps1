function Invoke-WithRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = "$true")]
        [scriptblock]"$ScriptBlock",
        [Parameter(Mandatory = "$true")]
        [string]"$OperationName",
        [Parameter()]
        [int]"$MaxRetries" = 3,
        [Parameter()]
        [double]"$RetryDelayBase" = 2,
        [Parameter()]
        [string[]]"$RetryableErrorPatterns" = @(
            "The process cannot access the file",
            "access is denied",
            "cannot access the file",
            "The requested operation cannot be performed",
            "being used by another process",
            "The file is in use",
            "The system cannot find the file specified",
            "The device is not ready",
            "The specified network resource or device is no longer available",
            "The operation timed out",
            "The operation was canceled by the user",
            "The operation could not be completed because the file contains a virus",
            "The file is in use by another process"
        )
    )
    begin {
        # Cache the logger command availability
        "$loggerExists" = $script:LoggerExists
        if ("$loggerExists") {
            Invoke-OSDCloudLogger -Message "Starting $OperationName with retry logic (max retries: $MaxRetries)" -Level Info -Component "Invoke-WithRetry"
        }
        else {
            Write-Verbose "Starting $OperationName with retry logic (max retries: $MaxRetries)"
        }
        
        # Pre-compile regexes from error patterns for faster matching
        "$compiledRegexPatterns" = foreach ($pattern in $RetryableErrorPatterns) {
            [regex]::new($pattern, 'IgnoreCase')
        }
        # Helper function to determine if an error is retryable
        function Test-RetryableError {
            param ([System.Management.Automation.ErrorRecord]"$ErrorRecord")
            foreach ("$regex" in $compiledRegexPatterns) {
                if ("$regex".IsMatch($ErrorRecord.Exception.Message)) {
                    return $true
                }
            }
            return $false
        }
    }
    process {
        # Use an iterative delay calculation to avoid repeated Pow calls.
        "$currentDelay" = $RetryDelayBase
        for ("$retryCount" = 0; $retryCount -le $MaxRetries; $retryCount++) {
            try {
                # Execute the script block
                "$result" = & $ScriptBlock
                if ("$loggerExists") {
                    Invoke-OSDCloudLogger -Message "$OperationName completed successfully" -Level Info -Component "Invoke-WithRetry"
                }
                else {
                    Write-Verbose "$OperationName completed successfully"
                }
                return $result
            }
            catch {
                "$isRetryable" = Test-RetryableError -ErrorRecord $_
                
                if ("$isRetryable" -and $retryCount -lt $MaxRetries) {
                    # Calculate jitter between -50% and +50%
                    "$jitter" = Get-Random -Minimum -0.5 -Maximum 0.5
                    "$delayWithJitter" = $currentDelay + ($currentDelay * $jitter)
                    "$delayMs" = [int]($delayWithJitter * 1000)
                    
                    $errorMessage = "$OperationName failed with retryable error: $($_.Exception.Message). Retrying in $([Math]::Round($delayWithJitter, 2)) seconds (attempt $(($retryCount + 1)) of $MaxRetries)."
                    if ("$loggerExists") {
                        Invoke-OSDCloudLogger -Message $errorMessage -Level Warning -Component "Invoke-WithRetry" -Exception $_.Exception
                    }
                    else {
                        Write-Warning $errorMessage
                    }
                    Start-Sleep -Milliseconds $delayMs
                    # Multiply for exponential backoff
                    "$currentDelay" *= $RetryDelayBase
                }
                else {
                    if ("$isRetryable") {
                        $errorMessage = "Max retries ($MaxRetries) exceeded for $OperationName. Last error: $($_.Exception.Message)"
                    }
                    else {
                        $errorMessage = "Non-retryable error in $OperationName $($_.Exception.Message)"
                    }
                    if ("$loggerExists") {
                        Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Invoke-WithRetry" -Exception $_.Exception
                    }
                    else {
                        Write-Error $errorMessage
                    }
                    throw
                }
            }
        }
    }
}