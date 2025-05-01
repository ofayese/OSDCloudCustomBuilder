# Function: Write-OSDCloudLog
# Author: Oluwaseun Fayese
# Company: Modern Endpoint Management
# Last Modified: April 19, 2025

<#
.SYNOPSIS
    Writes a log message to the OSDCloud log file.
.DESCRIPTION
    This function writes a log message to the OSDCloud log file and optionally
    to the console. It supports different log levels (Info, Warning, Error, Debug)
    and can include additional information such as the component that generated
    the log message.
.PARAMETER Message
    The log message to write.
.PARAMETER Level
    The log level (Info, Warning, Error, Debug).
.PARAMETER Component
    The component that generated the log message.
.PARAMETER Exception
    An exception object to include in the log message.
.PARAMETER NoConsole
    If specified, the message will not be written to the console.
.EXAMPLE
    Write-OSDCloudLog -Message "Starting process" -Level Info -Component "Initialize"
.EXAMPLE
    Write-OSDCloudLog -Message "Error occurred" -Level Error -Component "Process" -Exception $_.Exception
.NOTES
    This function is used internally by other module functions.
#>
function Write-OSDCloudLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info',
        
        [Parameter()]
        [string]$Component = 'OSDCloudCustomBuilder',
        
        [Parameter()]
        [System.Exception]$Exception,
        
        [Parameter()]
        [switch]$NoConsole
    )
    
    process {
        # Check if the logger exists
        if ($script:LoggerExists) {
            # Use the OSDCloud logger if available
            try {
                $params = @{
                    Message = $Message
                    Level = $Level
                    Component = $Component
                }
                
                if ($Exception) {
                    $params.Exception = $Exception
                }
                
                if ($NoConsole) {
                    $params.NoConsole = $true
                }
                
                Invoke-OSDCloudLogger @params
            }
            catch {
                # Fallback to simple logging if the logger fails
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $logMessage = "[$timestamp] [$Level] [$Component] $Message"
                
                if (-not $NoConsole) {
                    switch ($Level) {
                        'Info'    { Write-Host $logMessage }
                        'Warning' { Write-Warning $Message }
                        'Error'   { Write-Error $Message }
                        'Debug'   { Write-Debug $logMessage }
                        default   { Write-Host $logMessage }
                    }
                }
            }
        }
        else {
            # Simple logging
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logMessage = "[$timestamp] [$Level] [$Component] $Message"
            
            if (-not $NoConsole) {
                switch ($Level) {
                    'Info'    { Write-Host $logMessage }
                    'Warning' { Write-Warning $Message }
                    'Error'   { Write-Error $Message }
                    'Debug'   { Write-Debug $logMessage }
                    default   { Write-Host $logMessage }
                }
            }
            
            # Try to write to a log file
            try {
                $config = Get-ModuleConfiguration -ErrorAction SilentlyContinue
                if ($config -and $config.Paths -and $config.Paths.Logs) {
                    $logPath = $config.Paths.Logs
                    if (-not (Test-Path -Path $logPath -PathType Container)) {
                        New-Item -Path $logPath -ItemType Directory -Force | Out-Null
                    }
                    
                    $logFile = Join-Path -Path $logPath -ChildPath "OSDCloudCustomBuilder.log"
                    Add-Content -Path $logFile -Value $logMessage -Force
                }
            }
            catch {
                # Ignore errors writing to the log file
                Write-Debug "Failed to write to log file: $_"
            }
        }
    }
}

Export-ModuleMember -Function Write-OSDCloudLog