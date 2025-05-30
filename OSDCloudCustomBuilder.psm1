<#
.SYNOPSIS
    Advanced PowerShell module for enhancing OSDCloud with custom Windows image integration and PowerShell 7 support.
.DESCRIPTION
    OSDCloudCustomBuilder extends OSDCloud capabilities with specialized tools for creating tailored deployment media.
    Key features include:
    - PowerShell 7 integration into WinPE environments
    - Custom Windows image (WIM) processing and optimization
    - ISO creation with enhanced boot options
    - Comprehensive error handling and logging system
    - Telemetry for enterprise deployment monitoring
    - Documentation generation from code comments
.NOTES
    Version: 0.3.1
    Author: Laolu Fayese
    Copyright: (c) 2025 Modern Endpoint Management. All rights reserved.
#>

#requires -Version 5.1
#requires -Modules @{ ModuleName="OSD"; ModuleVersion="23.5.2" }

#region Module Setup
# Get module version from manifest to ensure consistency
$ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath 'OSDCloudCustomBuilder.psd1'
try {
    $Manifest = Import-PowerShellDataFile -Path $ManifestPath -ErrorAction Stop
    $script:ModuleVersion = $Manifest.ModuleVersion
} catch {
    # Fallback version if manifest can't be read
    $script:ModuleVersion = "0.3.1"
    Write-Warning "Could not read module version from manifest: $_"
}

# Support for different PowerShell module paths
$PSModuleRoot = $PSScriptRoot
if (-not $PSModuleRoot) {
    if ($ExecutionContext.SessionState.Module.PrivateData.PSPath) {
        $PSModuleRoot = Split-Path -Path $ExecutionContext.SessionState.Module.PrivateData.PSPath
    } else {
        $PSModuleRoot = $PWD.Path
        Write-Warning "Could not determine module root path, using current directory: $PSModuleRoot"
    }
}
$script:ModuleRoot = $PSModuleRoot
Write-Verbose "Loading OSDCloudCustomBuilder module v$script:ModuleVersion from $script:ModuleRoot"

# Enforce TLS 1.2 for secure communications with PS edition awareness
if ($PSEdition -ne 'Core') {
    # Only needed for Windows PowerShell; PowerShell Core handles this automatically
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Verbose "TLS 1.2 protocol enforced: $([Net.ServicePointManager]::SecurityProtocol)"
} else {
    Write-Verbose "Running on PowerShell Core - TLS configuration handled automatically"
}

# Set strict mode to catch common issues
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Check environment compatibility
try {
    # Import SharedUtilities module for Test-EnvironmentCompatibility
    $sharedUtilitiesPath = Join-Path -Path $PSModuleRoot -ChildPath "Shared\SharedUtilities.psm1"
    if (Test-Path -Path $sharedUtilitiesPath) {
        Import-Module -Name $sharedUtilitiesPath -Force -ErrorAction Stop
    }

    # Define required modules
    $requiredModules = @{
        "ThreadJob" = @{ MinimumVersion = "2.0.0"; Required = $false }
    }

    # Check environment compatibility
    $compatibility = Test-EnvironmentCompatibility -RequiredModules $requiredModules -MinimumPSVersion ([Version]'5.1')

    # Display warnings for optional modules
    foreach ($warning in $compatibility.Warnings) {
        Write-Warning $warning
    }

    # Throw error if environment is not compatible
    if (-not $compatibility.IsCompatible) {
        $errorMsg = "Environment is not compatible: $($compatibility.Issues -join '; ')"
        Write-Error $errorMsg
        throw $errorMsg
    }
} catch {
    if ($_.Exception.Message -like "The term 'Test-EnvironmentCompatibility' is not recognized*") {
        # Fallback to basic PowerShell version check if Test-EnvironmentCompatibility is not available
        $requiredPSVersion = [Version]'5.1'
        if ($PSVersionTable.PSVersion -lt $requiredPSVersion) {
            $errorMsg = "PowerShell $($requiredPSVersion) or higher is required. Current version: $($PSVersionTable.PSVersion)"
            Write-Error $errorMsg
            throw $errorMsg
        }
    } else {
        # Re-throw other errors
        throw
    }
}

# Define path to PowerShell 7 package in the OSDCloud folder
$script:PowerShell7ZipPath = Join-Path -Path (Split-Path -Parent $script:ModuleRoot) -ChildPath "OSDCloud\PowerShell-7.5.1-win-x64.zip"
if ([System.IO.File]::Exists($script:PowerShell7ZipPath)) {
    Write-Verbose "PowerShell 7 package found at: $script:PowerShell7ZipPath"
    $script:PowerShell7Available = $true
} else {
    Write-Verbose "PowerShell 7 package not found at: $script:PowerShell7ZipPath"
    Write-Verbose "PowerShell 7 integration features will be limited. To enable full functionality, download PowerShell 7.5.1 and place the zip file at the expected location."
    $script:PowerShell7Available = $false
}

# Check if running in PS7+ for faster methods
$script:IsPS7OrHigher = $PSVersionTable.PSVersion.Major -ge 7

# Set module-level variables
$script:EnableVerboseLogging = $false

# Initialize logging system
function Initialize-ModuleLogging {
    [OutputType([void])]
    [CmdletBinding()]
    param()

    if ($script:EnableVerboseLogging) {
        Write-Verbose 'Verbose logging enabled.'
    }
    $script:LoggerExists = $false
    try {
        $loggerCommand = Get-Command -Name Invoke-OSDCloudLogger -ErrorAction Stop
        $script:LoggerExists = $true
        Write-Verbose "OSDCloud logger found: $($loggerCommand.Source)"
    } catch {
        Write-Verbose "OSDCloud logger not available, using standard logging"
    }

    # Create a fallback logging function if needed
    if (-not $script:LoggerExists) {
        if (-not (Get-Command -Name Write-OSDCloudLog -ErrorAction SilentlyContinue)) {
            function script:Write-OSDCloudLog {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory = $true, Position = 0)]
                    [string] $Message,
                    [Parameter()]
                    [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
                    [string] $Level = 'Info',
                    [Parameter()]
                    [string] $Component = 'OSDCloudCustomBuilder',
                    [Parameter()]
                    [System.Exception] $Exception
                )

                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $logMessage = "[$timestamp] [$Level] [$Component] $Message"

                switch ($Level) {
                    'Info' { Write-Host $logMessage }
                    'Warning' { Write-Warning $Message }
                    'Error' { Write-Error $Message }
                    'Debug' { Write-Debug $logMessage }
                    default { Write-Host $logMessage }
                }

                # If an exception was provided, output additional details
                if ($Exception) {
                    $exceptionMessage = "[$timestamp] [$Level] [$Component] Exception: $($Exception.Message)"
                    $stackTraceMessage = "[$timestamp] [$Level] [$Component] Stack Trace: $($Exception.StackTrace)"

                    switch ($Level) {
                        'Info' { Write-Host $exceptionMessage; Write-Host $stackTraceMessage }
                        'Warning' { Write-Warning $exceptionMessage; Write-Warning $stackTraceMessage }
                        'Error' { Write-Error $exceptionMessage; Write-Error $stackTraceMessage }
                        'Debug' { Write-Debug $exceptionMessage; Write-Debug $stackTraceMessage }
                        default { Write-Host $exceptionMessage; Write-Host $stackTraceMessage }
                    }
                }
            }
        }
    }
}

# Call the logging initialization
Initialize-ModuleLogging

#region Function Import
# Check for required dependencies
$requiredModules = @{
    "ThreadJob" = @{
        Required       = $false
        MinimumVersion = "2.0.0"
        Message        = "ThreadJob module is recommended for improved parallel processing performance."
    }
}

foreach ($moduleName in $requiredModules.Keys) {
    $moduleInfo = $requiredModules[$moduleName]
    $module = Get-Module -Name $moduleName -ListAvailable |
    Where-Object { $_.Version -ge $moduleInfo.MinimumVersion } |
    Sort-Object -Property Version -Descending |
    Select-Object -First 1

    if (-not $module) {
        if ($moduleInfo.Required) {
            $errorMsg = "Required module $moduleName (minimum version: $($moduleInfo.MinimumVersion)) not found. Please install it using: Install-Module -Name $moduleName -MinimumVersion $($moduleInfo.MinimumVersion) -Force"
            Write-Error $errorMsg
            throw $errorMsg
        } else {
            Write-Warning "$($moduleInfo.Message)"
        }
    } else {
        Write-Verbose "Found $moduleName module v$($module.Version)"
    }
}

# Import Shared Utilities Module (remove redundant .ps1 import)
# The SharedUtilities.psm1 is already imported above for environment compatibility
Write-Verbose "SharedUtilities module already imported for environment compatibility"

# Import Private Functions
$PrivateFunctions = @(Get-ChildItem -Path "$PSModuleRoot\Private" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue)
foreach ($Private in $PrivateFunctions) {
    try {
        . $Private.FullName
        Write-Verbose "Imported private function: $($Private.BaseName)"
    } catch {
        Write-Warning "Failed to import private function $($Private.FullName): $_"
    }
}

# Import Public Functions
$PublicFunctions = @(Get-ChildItem -Path "$PSModuleRoot\Public" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue)
foreach ($Public in $PublicFunctions) {
    try {
        . $Public.FullName
        Write-Verbose "Imported public function: $($Public.BaseName)"
    } catch {
        Write-Warning "Failed to import public function $($Public.FullName): $_"
    }
}

# Export public functions from manifest if available, otherwise export all public functions
if ($Manifest -and $Manifest.FunctionsToExport) {
    $FunctionsToExport = $Manifest.FunctionsToExport
} else {
    $FunctionsToExport = $PublicFunctions.BaseName
}

# Export aliases if defined in manifest
if ($Manifest -and $Manifest.AliasesToExport) {

} else {

}
#endregion Function Import

# Module initialization code - runs when module is imported
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"

# Initialize default configuration if needed
if (-not (Test-Path -Path $script:ConfigPath)) {
    $defaultConfig = @{
        OrganizationName = "Default Organization"
        LoggingEnabled   = $true
        LogLevel         = "Info"
        SchemaVersion    = "1.0"
    }
    $defaultConfig | ConvertTo-Json | Out-File -FilePath $script:ConfigPath -Encoding utf8 -Force
}

# Display module information
Write-Verbose "OSDCloudCustomBuilder v$script:ModuleVersion loaded successfully."
Write-Verbose "Use 'Get-Command -Module OSDCloudCustomBuilder' to see available commands."
Write-Verbose "Use 'Get-Help <command-name> -Full' for detailed help on each command."
#endregion Module Setup

# Export all functions defined in the manifest
$FunctionsToExport = @(
    'Add-OSDCloudCustomDriver',
    'Add-OSDCloudCustomScript',
    'Enable-OSDCloudTelemetry',
    'Get-PWsh7WrappedContent',
    'New-CustomOSDCloudISO',
    'New-OSDCloudCustomMedia',
    'Set-OSDCloudCustomSettings',
    'Set-OSDCloudTelemetry',
    'Test-OSDCloudCustomRequirements',
    'Update-CustomWimWithPwsh7',
    'Update-CustomWimWithPwsh7Advanced'
)

Export-ModuleMember -Function $FunctionsToExport
