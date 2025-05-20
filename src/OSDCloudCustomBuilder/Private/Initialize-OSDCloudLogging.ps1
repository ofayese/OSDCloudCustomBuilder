function Initialize-OSDCloudLogging {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]$Force
    )
    
    # Skip initialization if already done unless Force is specified
    if ($script:LogFile -and -not $Force) {
        Write-Verbose "Logging system already initialized. Use -Force to reinitialize."
        return
    }
    
    # Close existing log file if any
    if ($script:LogWriter) {
        try {
            $script:LogWriter.Close()
            $script:LogWriter.Dispose()
            $script:LogWriter = $null
        }
        catch {
            Write-Warning "Error closing existing log writer: $_"
        }
    }
    
    if ($script:LogFileStream) {
        try {
            $script:LogFileStream.Close()
            $script:LogFileStream.Dispose()
            $script:LogFileStream = $null
        }
        catch {
            Write-Warning "Error closing existing log file stream: $_"
        }
    }
    
    # Get logging configuration from module settings
    try {
        $config = Get-ModuleConfiguration
        
        # Default log path if not in config or config loading fails
        $logPath = Join-Path -Path $env:TEMP -ChildPath "OSDCloudCustomBuilder.log"
        
        # Use configured log path if available
        if ($config -and $config.ContainsKey('LogPath')) {
            $logPath = $config.LogPath
        }
        
        # Create directory if it doesn't exist
        $logDir = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDir)) {
            $null = New-Item -Path $logDir -ItemType Directory -Force
        }
        
        # Set up file logging
        $script:LogFile = $logPath
        $script:LogFileStream = [System.IO.FileStream]::new($script:LogFile, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
        $script:LogWriter = [System.IO.StreamWriter]::new($script:LogFileStream)
        
        # Additional logging settings
        $script:EnableConsoleLogging = $true
        $script:EnableFileLogging = $true
        $script:EnableEventLogging = $false
        $script:MinimumLogLevel = [LogLevel]::Info
        
        # Override defaults with config values if present
        if ($config) {
            if ($config.ContainsKey('Logging')) {
                $logConfig = $config.Logging
                
                if ($logConfig.ContainsKey('EnableConsoleLogging')) {
                    $script:EnableConsoleLogging = $logConfig.EnableConsoleLogging
                }
                
                if ($logConfig.ContainsKey('EnableFileLogging')) {
                    $script:EnableFileLogging = $logConfig.EnableFileLogging
                }
                
                if ($logConfig.ContainsKey('EnableEventLogging')) {
                    $script:EnableEventLogging = $logConfig.EnableEventLogging
                }
                
                if ($logConfig.ContainsKey('MinimumLogLevel')) {
                    $levelName = $logConfig.MinimumLogLevel
                    if ([Enum]::TryParse([LogLevel], $levelName, [ref]$null)) {
                        $script:MinimumLogLevel = [LogLevel]$levelName
                    }
                }
            }
            
            # Handle EnableVerboseLogging as a shortcut to set debug level
            if ($config.ContainsKey('EnableVerboseLogging') -and $config.EnableVerboseLogging) {
                $script:MinimumLogLevel = [LogLevel]::Debug
            }
        }
        
        # Set up EventLog source if enabled
        if ($script:EnableEventLogging) {
            $source = "OSDCloudCustomBuilder"
            $logName = "Application"
            
            # Check if the source exists, create if not (requires admin)
            if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
                try {
                    [System.Diagnostics.EventLog]::CreateEventSource($source, $logName)
                    Write-Verbose "Created EventLog source: $source"
                }
                catch {
                    Write-Warning "Failed to create EventLog source: $_"
                    $script:EnableEventLogging = $false
                }
            }
        }
        
        # Log initialization info
        $initMessage = "Logging initialized. File: $script:LogFile, Level: $script:MinimumLogLevel, Outputs: "
        $outputs = @()
        if ($script:EnableConsoleLogging) { $outputs += "Console" }
        if ($script:EnableFileLogging) { $outputs += "File" }
        if ($script:EnableEventLogging) { $outputs += "EventLog" }
        $initMessage += ($outputs -join ", ")
        
        Write-Verbose $initMessage
        if ($script:EnableFileLogging) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $script:LogWriter.WriteLine("[$timestamp] [Info] $initMessage")
            $script:LogWriter.Flush()
        }
        
        # Reset statistics
        $script:LogStats = [LogStatistics]::new()
    }
    catch {
        # Fallback to console-only logging if initialization fails
        Write-Warning "Failed to initialize logging system: $_"
        $script:EnableConsoleLogging = $true
        $script:EnableFileLogging = $false
        $script:EnableEventLogging = $false
        $script:MinimumLogLevel = [LogLevel]::Info
    }
}