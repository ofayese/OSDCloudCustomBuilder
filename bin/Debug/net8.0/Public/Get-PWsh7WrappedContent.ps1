<#
.SYNOPSIS
    Get-PWsh7WrappedContent - Performs a key function for OSDCloud customization.

.DESCRIPTION
    Detailed explanation for Get-PWsh7WrappedContent. This function plays a role in OSDCloud automation and system prep workflows.

.EXAMPLE
    PS> Get-PWsh7WrappedContent -Param1 Value1

.PARAMETER true
    Description of `true` parameter.

.NOTES
    Author: OSDCloud Team
    Date: 2025-05-26
#>

<#
.SYNOPSIS
    takes - Brief summary of what the function does.

.DESCRIPTION
    Detailed description for takes. This should explain the purpose, usage, and examples.

.EXAMPLE
    PS> takes

.NOTES
    Author: YourName
    Date: 1748138720.8589237
#>

# Function: Get-PWsh7WrappedContent
# Author: Oluwaseun Fayese
# Company: Modern Endpoint Management
# Last Modified: April 20, 2025

<#
.SYNOPSIS
    Wraps PowerShell code in a structure that ensures it runs properly in PowerShell 7.
.DESCRIPTION
    This function takes PowerShell code as input and wraps it in a structure that ensures
    it runs properly in PowerShell 7 environments, including error handling and logging.
    It's useful for preparing scripts that will be injected into WinPE environments with
    PowerShell 7 support.
.PARAMETER Content
    The PowerShell code to wrap. Can be null or empty.
.PARAMETER AddErrorHandling
    If specified, adds comprehensive error handling to the wrapped code.
.PARAMETER AddLogging
    If specified, adds logging statements to the wrapped code.
.PARAMETER LogPath
    The path where logs will be written if AddLogging is specified.
    Default is "X:\OSDCloud\Logs".
.PARAMETER IncludeTimestamp
    If specified, adds a timestamp to log entries.
.PARAMETER LogLevel
    Sets the minimum log level to record. Valid values are "Debug", "Info", "Warning", "Error".
    Default is "Info".
.EXAMPLE
    Get-PWsh7WrappedContent -Content 'Write-Host "Hello from PowerShell 7"'
.EXAMPLE
    Get-PWsh7WrappedContent -Content $scriptContent -AddErrorHandling -AddLogging -LogPath "X:\OSDCloud\Logs"
.EXAMPLE
    Get-PWsh7WrappedContent -Content $scriptContent -AddLogging -LogLevel "Debug" -IncludeTimestamp
.NOTES
    This function is useful when preparing scripts for the OSDCloud environment.
    Updated in v0.3.0 to handle null/empty content and add more logging options.
#>
function Get-PWsh7WrappedContent {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Content,
        
        [Parameter()]
        [switch]$AddErrorHandling,
        
        [Parameter()]
        [switch]$AddLogging,
        
        [Parameter()]
        [string]$LogPath = "X:\OSDCloud\Logs",
        
        [Parameter()]
        [switch]$IncludeTimestamp,
        
        [Parameter()]
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$LogLevel = "Info"
    )
    
    begin {
        # Handle null or empty content
        if ([string]::IsNullOrEmpty($Content)) {
            Write-Verbose "Empty or null content provided. Using a placeholder comment."
            $Content = "# Empty script content provided"
        }
        
        # Configure logging based on module configuration if available
        $config = $null
        if (Get-Command -Name Get-ModuleConfiguration -ErrorAction SilentlyContinue) {
            try {
                $config = Get-ModuleConfiguration
                if ($config -and $config.PowerShell7 -and $config.PowerShell7.Logging) {
                    $logConfig = $config.PowerShell7.Logging
                    if ($logConfig.DefaultPath -and -not $PSBoundParameters.ContainsKey('LogPath')) {
                        $LogPath = $logConfig.DefaultPath
                    }
                    if ($logConfig.IncludeTimestamp -and -not $PSBoundParameters.ContainsKey('IncludeTimestamp')) {
                        $IncludeTimestamp = $logConfig.IncludeTimestamp
                    }
                    if ($logConfig.DefaultLevel -and -not $PSBoundParameters.ContainsKey('LogLevel')) {
                        $LogLevel = $logConfig.DefaultLevel
                    }
                }
            }
            catch {
                Write-Verbose "Error getting module configuration: $_. Using default values."
            }
        }
    }
    
    process {
        # Basic wrapper with minimal scaffolding
        $wrappedContent = @"
try {
    # PowerShell 7 script content
$Content
}
catch {
    # Error handling for PowerShell 7 execution
    Write-Error "Error executing PowerShell 7 code: `$_"
    throw
}
"@

        # Add comprehensive error handling if requested
        if ($AddErrorHandling) {
            $wrappedContent = @"
try {
    # PowerShell 7 script content
    `$ErrorActionPreference = 'Stop'
    `$VerbosePreference = 'Continue'
    
    # Script execution
$Content
}
catch {
    # Comprehensive error handling
    `$errorRecord = `$_
    `$errorMessage = "Error executing PowerShell 7 code: `$(`$errorRecord.Exception.Message)"
    `$errorLine = `$errorRecord.InvocationInfo.ScriptLineNumber
    `$errorPosition = `$errorRecord.InvocationInfo.PositionMessage
    `$errorType = `$errorRecord.Exception.GetType().FullName
    `$errorStackTrace = `$errorRecord.ScriptStackTrace
    
    Write-Error "`$errorMessage"
    Write-Error "Line: `$errorLine"
    Write-Error "Position: `$errorPosition"
    Write-Error "Type: `$errorType"
    Write-Error "Stack Trace: `$errorStackTrace"
    
    # Re-throw the error for proper handling upstream
    throw `$errorRecord
}
finally {
    # Cleanup code here if needed
    [System.GC]::Collect()
}
"@
        }
        
        # Add logging if requested
        if ($AddLogging) {
            $timestampFormat = if ($IncludeTimestamp) { '$(Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")' } else { '$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")' }
            $logFileName = "PWsh7Execution_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            $logFilePath = Join-Path -Path $LogPath -ChildPath $logFileName
            
            $logLevelMapping = @"
    # Log level mapping
    `$logLevelMap = @{
        "DEBUG"   = 0
        "INFO"    = 1
        "WARNING" = 2
        "ERROR"   = 3
    }
    
    # Set minimum log level
    `$minimumLogLevel = "$LogLevel".ToUpper()
    `$minimumLogLevelValue = `$logLevelMap[`$minimumLogLevel]
"@
            
            $wrappedContent = @"
# Initialize logging
`$logFilePath = "$logFilePath"
`$logDirectory = Split-Path -Path `$logFilePath -Parent

if (-not (Test-Path -Path `$logDirectory)) {
    New-Item -Path `$logDirectory -ItemType Directory -Force | Out-Null
}

$logLevelMapping

function Write-PWsh7Log {
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$Message,
        
        [Parameter()]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]`$Level = "INFO",
        
        [Parameter()]
        [string]`$Component = "PWsh7"
    )
    
    # Check if we should log this level
    if (`$logLevelMap[`$Level] -lt `$logLevelMap[`$minimumLogLevel]) {
        return
    }
    
    `$timestamp = $timestampFormat
    `$logEntry = "[`$timestamp] [`$Level] [`$Component] `$Message"
    
    # Write to console with appropriate color
    switch (`$Level) {
        "ERROR"   { 
            Write-Error `$Message 
        }
        "WARNING" { 
            Write-Warning `$Message 
        }
        "INFO"    { 
            Write-Host `$Message 
        }
        "DEBUG"   { 
            if (`$VerbosePreference -eq 'Continue') {
                Write-Verbose `$Message
            }
        }
        default   { 
            Write-Host `$Message 
        }
    }
    
    # Write to log file
    try {
        Add-Content -Path `$logFilePath -Value `$logEntry -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to write to log file: `$_"
    }
}

Write-PWsh7Log -Message "Starting PowerShell 7 script execution" -Level "INFO"
Write-PWsh7Log -Message "Log file: `$logFilePath" -Level "DEBUG"
Write-PWsh7Log -Message "PowerShell Version: `$(`$PSVersionTable.PSVersion)" -Level "DEBUG"
Write-PWsh7Log -Message "OS: `$(`$PSVersionTable.OS)" -Level "DEBUG"

try {
    # PowerShell 7 script content
    `$ErrorActionPreference = 'Stop'
    `$VerbosePreference = 'Continue'
    
    Write-PWsh7Log -Message "Script environment initialized" -Level "INFO"
    
    # Script execution
$Content

    Write-PWsh7Log -Message "Script execution completed successfully" -Level "INFO"
}
catch {
    # Comprehensive error handling with logging
    `$errorRecord = `$_
    `$errorMessage = "Error executing PowerShell 7 code: `$(`$errorRecord.Exception.Message)"
    `$errorLine = `$errorRecord.InvocationInfo.ScriptLineNumber
    `$errorPosition = `$errorRecord.InvocationInfo.PositionMessage
    `$errorType = `$errorRecord.Exception.GetType().FullName
    `$errorStackTrace = `$errorRecord.ScriptStackTrace
    
    Write-PWsh7Log -Message "`$errorMessage" -Level "ERROR"
    Write-PWsh7Log -Message "Line: `$errorLine" -Level "ERROR"
    Write-PWsh7Log -Message "Position: `$errorPosition" -Level "ERROR"
    Write-PWsh7Log -Message "Type: `$errorType" -Level "ERROR"
    Write-PWsh7Log -Message "Stack Trace: `$errorStackTrace" -Level "ERROR"
    
    # Re-throw the error for proper handling upstream
    throw `$errorRecord
}
finally {
    # Cleanup code here if needed
    Write-PWsh7Log -Message "Script execution finished" -Level "INFO"
    [System.GC]::Collect()
}
"@
        }
        
        return $wrappedContent
    }
}

Export-ModuleMember -Function Get-PWsh7WrappedContent