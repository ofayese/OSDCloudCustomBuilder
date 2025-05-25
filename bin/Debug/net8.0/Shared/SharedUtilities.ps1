function Test-IsAdmin {
    <#
    .SYNOPSIS
        Tests if the current PowerShell session is running with administrator privileges.
    .DESCRIPTION
        Determines whether the current user has administrator privileges on Windows or is running as root on Linux/macOS.
    .EXAMPLE
        if (Test-IsAdmin) { Write-Host "Running as admin" }
    .OUTPUTS
        System.Boolean
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param()

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-LogMessage {
    <#
    .SYNOPSIS
        Writes a formatted log message with timestamp.
    .DESCRIPTION
        Writes a log message to the console and optionally to a log file with timestamp and severity level.
    .PARAMETER Message
        The message to log.
    .PARAMETER Level
        The severity level of the message (Debug, Info, Warning, Error, Fatal).
    .PARAMETER LogToFile
        Whether to write the message to a log file.
    .EXAMPLE
        Write-LogMessage -Message "Processing started" -Level Info
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Position = 1)]
        [ValidateSet('Debug', 'Info', 'Warning', 'Error', 'Fatal')]
        [string]$Level = 'Info',

        [Parameter()]
        [switch]$LogToFile
    )

    # Only output verbose messages if verbose logging is enabled
    if ($Level -eq 'Debug' -and -not $script:EnableVerboseLogging) {
        return
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'Debug' {
            Write-Verbose $logMessage
        }
        'Info' {
            Write-Host $logMessage -ForegroundColor Cyan
        }
        'Warning' {
            Write-Warning $logMessage
        }
        'Error' {
            Write-Error $logMessage
        }
        'Fatal' {
            Write-Error $logMessage
            throw $Message
        }
    }

    if ($LogToFile -and $script:LogPath) {
        Add-Content -Path $script:LogPath -Value $logMessage
    }
}

function Test-RequiredModule {
    <#
    .SYNOPSIS
        Tests if a required module is installed.
    .DESCRIPTION
        Checks if a module is installed and optionally validates the version.
    .PARAMETER ModuleName
        The name of the module to check.
    .PARAMETER MinimumVersion
        The minimum required version of the module.
    .EXAMPLE
        Test-RequiredModule -ModuleName "OSD" -MinimumVersion "23.5.2"
    .OUTPUTS
        System.Boolean
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [Parameter()]
        [version]$MinimumVersion
    )

    $module = Get-Module -Name $ModuleName -ListAvailable

    if (-not $module) {
        return $false
    }

    if ($MinimumVersion) {
        $latestVersion = ($module | Sort-Object -Property Version -Descending | Select-Object -First 1).Version
        return $latestVersion -ge $MinimumVersion
    }

    return $true
}
