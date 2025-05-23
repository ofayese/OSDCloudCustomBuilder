<#
.SYNOPSIS
    Shared utility functions for OSDCloudCustomBuilder module.
.DESCRIPTION
    This module contains shared utility functions used by the OSDCloudCustomBuilder module.
    These functions provide common functionality like environment compatibility checking,
    error handling, and other utilities.
.NOTES
    Version: 0.3.1
    Author: Laolu Fayese
    Copyright: (c) 2025 Modern Endpoint Management. All rights reserved.
#>

#region Environment Functions

<#
.SYNOPSIS
    Tests if the current environment is compatible with the module requirements.
.DESCRIPTION
    Checks if the PowerShell version and required modules meet the minimum requirements.
    Returns a hashtable with compatibility information.
.PARAMETER RequiredModules
    A hashtable of required modules with their minimum versions and whether they are required or optional.
.PARAMETER MinimumPSVersion
    The minimum PowerShell version required.
.EXAMPLE
    $requiredModules = @{
        "ThreadJob" = @{ MinimumVersion = "2.0.0"; Required = $false }
    }
    $compatibility = Test-EnvironmentCompatibility -RequiredModules $requiredModules -MinimumPSVersion ([Version]'5.1')
.OUTPUTS
    [System.Collections.Hashtable]
#>
function Test-EnvironmentCompatibility {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter()]
        [hashtable] $RequiredModules = @{},
        
        [Parameter()]
        [version] $MinimumPSVersion = [version]'5.1'
    )
    
    $result = @{
        IsCompatible = $true
        Issues = @()
        Warnings = @()
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion -lt $MinimumPSVersion) {
        $result.IsCompatible = $false
        $result.Issues += "PowerShell $MinimumPSVersion or higher is required. Current version: $($PSVersionTable.PSVersion)"
    }
    
    # Check required modules
    foreach ($moduleName in $RequiredModules.Keys) {
        $moduleInfo = $RequiredModules[$moduleName]
        $minimumVersion = $moduleInfo.MinimumVersion
        $isRequired = $moduleInfo.Required
        
        $module = Get-Module -Name $moduleName -ListAvailable | 
                  Where-Object { $_.Version -ge $minimumVersion } | 
                  Sort-Object -Property Version -Descending | 
                  Select-Object -First 1
        
        if (-not $module) {
            if ($isRequired) {
                $result.IsCompatible = $false
                $result.Issues += "Required module $moduleName (minimum version: $minimumVersion) not found."
            } else {
                $result.Warnings += "Optional module $moduleName (minimum version: $minimumVersion) not found. Some features may not be available."
            }
        }
    }
    
    return $result
}

<#
.SYNOPSIS
    Tests if the current PowerShell version meets the minimum requirements.
.DESCRIPTION
    Checks if the PowerShell version meets the minimum requirements.
    Returns $true if the version is compatible, $false otherwise.
.PARAMETER MinimumVersion
    The minimum PowerShell version required.
.EXAMPLE
    $isCompatible = Test-PowerShellVersion -MinimumVersion ([Version]'5.1')
.OUTPUTS
    [System.Boolean]
#>
function Test-PowerShellVersion {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [version] $MinimumVersion
    )
    
    return $PSVersionTable.PSVersion -ge $MinimumVersion
}

<#
.SYNOPSIS
    Gets the current PowerShell edition.
.DESCRIPTION
    Returns the current PowerShell edition (Desktop or Core).
.EXAMPLE
    $edition = Get-PowerShellEdition
.OUTPUTS
    [System.String]
#>
function Get-PowerShellEdition {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    
    if ($PSVersionTable.PSEdition) {
        return $PSVersionTable.PSEdition
    } elseif ($PSVersionTable.PSVersion.Major -ge 6) {
        return 'Core'
    } else {
        return 'Desktop'
    }
}

<#
.SYNOPSIS
    Tests if the current PowerShell session is running as administrator.
.DESCRIPTION
    Checks if the current PowerShell session is running with administrator privileges.
    Returns $true if running as administrator, $false otherwise.
.EXAMPLE
    $isAdmin = Test-IsAdmin
.OUTPUTS
    [System.Boolean]
#>
function Test-IsAdmin {
    [CmdletBinding()]
    [OutputType([bool])]
    param ()
    
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

#endregion Environment Functions

#region Error Handling

<#
.SYNOPSIS
    Creates a new exception with additional context information.
.DESCRIPTION
    Creates a new exception with additional context information like the function name,
    line number, and other details to help with troubleshooting.
.PARAMETER Message
    The exception message.
.PARAMETER ErrorRecord
    The original error record, if available.
.PARAMETER Category
    The error category.
.PARAMETER FunctionName
    The name of the function where the error occurred.
.EXAMPLE
    throw (New-CustomException -Message "Failed to process file" -ErrorRecord $_ -Category InvalidOperation -FunctionName $MyInvocation.MyCommand)
.OUTPUTS
    [System.Exception]
#>
function New-CustomException {
    [CmdletBinding()]
    [OutputType([System.Exception])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Message,
        
        [Parameter()]
        [System.Management.Automation.ErrorRecord] $ErrorRecord,
        
        [Parameter()]
        [System.Management.Automation.ErrorCategory] $Category = [System.Management.Automation.ErrorCategory]::NotSpecified,
        
        [Parameter()]
        [string] $FunctionName = $MyInvocation.MyCommand.Name
    )
    
    $context = @{
        'Function' = $FunctionName
        'DateTime' = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        'PSVersion' = $PSVersionTable.PSVersion.ToString()
    }
    
    if ($ErrorRecord) {
        $context['OriginalError'] = $ErrorRecord.Exception.Message
        $context['ErrorCategory'] = $ErrorRecord.CategoryInfo.Category
        $context['ErrorID'] = $ErrorRecord.FullyQualifiedErrorId
    }
    
    $contextMessage = ($context.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join "; "
    $fullMessage = "$Message`n$contextMessage"
    
    if ($ErrorRecord) {
        $exception = New-Object System.Exception $fullMessage, $ErrorRecord.Exception
        $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $ErrorRecord.FullyQualifiedErrorId, $Category, $null
        return $errorRecord
    } else {
        return New-Object System.Exception $fullMessage
    }
}

<#
.SYNOPSIS
    Invokes a script block with retry logic.
.DESCRIPTION
    Invokes a script block with retry logic, with configurable retry count, delay, and backoff factor.
.PARAMETER ScriptBlock
    The script block to invoke.
.PARAMETER RetryCount
    The number of retry attempts.
.PARAMETER RetryDelaySeconds
    The initial delay between retries in seconds.
.PARAMETER BackoffFactor
    The factor by which to increase the delay after each retry.
.PARAMETER ErrorMessage
    The error message to display if all retries fail.
.EXAMPLE
    $result = Invoke-WithRetry -ScriptBlock { Get-Content -Path $filePath } -RetryCount 3 -RetryDelaySeconds 2 -BackoffFactor 2
.OUTPUTS
    [System.Object]
#>
function Invoke-WithRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        
        [Parameter()]
        [int] $RetryCount = 3,
        
        [Parameter()]
        [int] $RetryDelaySeconds = 2,
        
        [Parameter()]
        [double] $BackoffFactor = 2,
        
        [Parameter()]
        [string] $ErrorMessage = "Operation failed after multiple retry attempts"
    )
    
    $currentRetry = 0
    $success = $false
    $result = $null
    
    do {
        try {
            $result = & $ScriptBlock
            $success = $true
        } catch {
            $currentRetry++
            if ($currentRetry -ge $RetryCount) {
                Write-Error "$ErrorMessage. Final error: $_"
                throw (New-CustomException -Message $ErrorMessage -ErrorRecord $_ -Category OperationTimeout -FunctionName $MyInvocation.MyCommand)
            }
            
            $delay = $RetryDelaySeconds * [Math]::Pow($BackoffFactor, $currentRetry - 1)
            Write-Warning "Attempt $currentRetry of $RetryCount failed: $_. Retrying in $delay seconds..."
            Start-Sleep -Seconds $delay
        }
    } while (-not $success -and $currentRetry -lt $RetryCount)
    
    return $result
}

#endregion Error Handling

#region Export Module Members
Export-ModuleMember -Function @(
    'Test-EnvironmentCompatibility',
    'Test-PowerShellVersion',
    'Get-PowerShellEdition',
    'Test-IsAdmin',
    'New-CustomException',
    'Invoke-WithRetry'
)
#endregion Export Module Members
