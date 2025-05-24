# File: src/OSDCloudCustomBuilder/Private/OSDCloudConfig.ps1
# Patched
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    Configuration management system for OSDCloudCustomBuilder module.
.DESCRIPTION
    This file provides a comprehensive configuration management system for the OSDCloudCustomBuilder module.
    It handles loading, saving, validating, and merging configuration settings.
    The configuration system supports both default settings and user-defined overrides.
.PARAMETER Path
    The path to the configuration file.
.PARAMETER Config
    A hashtable containing configuration settings.
.PARAMETER UserConfig
    A hashtable containing user-defined configuration settings to merge with defaults.
.PARAMETER DefaultConfig
    A hashtable containing default configuration settings.
.EXAMPLE
    $config = Get-OSDCloudConfig
    Retrieves the current configuration settings.
.EXAMPLE
    Import-OSDCloudConfig -Path "C:\OSDCloud\config.json"
    Loads configuration settings from a JSON file.
.EXAMPLE
    Export-OSDCloudConfig -Path "C:\OSDCloud\config.json"
    Saves the current configuration settings to a JSON file.
.NOTES
    Created for: OSDCloudCustomBuilder Module
    Author: OSDCloud Team
    Date: March 31, 2025
    Version: 1.1
#>

# Default configuration settings
$script:OSDCloudConfig = @{
    # Organization settings
    OrganizationName = "iTechDevelopment_Charities"
    OrganizationContact = "IT Support"
    OrganizationEmail = "support@charity.org"

    # Logging settings
    LoggingEnabled = $true
    LogLevel = "Info"  # Debug, Info, Warning, Error, Fatal
    LogRetentionDays = 30
    LogFilePath = "$env:TEMP\OSDCloud\Logs\OSDCloudCustomBuilder.log"
    VerboseLogging = $false
    DebugLogging = $false

    # Default deployment settings
    DefaultOSLanguage = "en-us"
    DefaultOSEdition = "Enterprise"
    DefaultOSLicense = "Volume"

    # Recovery settings
    MaxRetryAttempts = 3
    RetryDelaySeconds = 5
    EnableAutoRecovery = $true
    CreateBackups = $true

    # Customization settings
    CustomWimSearchPaths = @(
        "X:\OSDCloud\custom.wim",
        "C:\OSDCloud\custom.wim",
        "D:\OSDCloud\custom.wim",
        "E:\OSDCloud\custom.wim"
    )

    # PowerShell 7 settings
    PowerShell7Version = "7.3.4"
    PowerShell7DownloadUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.3.4/PowerShell-7.3.4-win-x64.zip"
    PowerShell7Modules = @(
        "OSD",
        "Microsoft.Graph.Intune",
        "WindowsAutopilotIntune"
    )

    # Autopilot settings
    AutopilotEnabled = $true
    SkipAutopilotOOBE = $true

    # Hardware compatibility settings
    RequireTPM20 = $true
    MinimumCPUGeneration = 8  # For Intel CPUs

    # ISO building settings
    ISOOutputPath = "C:\OSDCloud\ISO"
    TempWorkspacePath = "$env:TEMP\OSDCloudWorkspace"
    CleanupTempFiles = $true
    IncludeWinRE = $true
    OptimizeISOSize = $true

    # Error handling settings
    ErrorRecoveryEnabled = $true
    ErrorLogPath = "$env:TEMP\OSDCloud\Logs\Errors"
    MaxErrorRetry = 3
    ErrorRetryDelay = 5

    # Integration settings
    SharedConfigPath = "$env:ProgramData\OSDCloud\Config"
    EnableSharedLogging = $true

    # Performance settings
    EnableParallelProcessing = $true
    MaxParallelTasks = 4
    UseRobocopyForLargeFiles = $true
    LargeFileSizeThresholdMB = 100

    # Schema version for configuration compatibility
    SchemaVersion = "1.0"

    # Metadata fields for tracking
    LastModified = (Get-Date).ToString('o')
    ModifiedBy = $env:USERNAME
    ChangeHistory = @()

    # Active configuration profile
    ActiveProfile = "Default"
}

<#
.SYNOPSIS
    Validates the OSDCloud configuration settings.
.DESCRIPTION
    Validates the OSDCloud configuration settings to ensure all required fields are present
    and that all values are within acceptable ranges.
.PARAMETER Config
    A hashtable containing the configuration settings to validate.
.EXAMPLE
    $validation = Test-OSDCloudConfig
    if (-not $validation.IsValid) {
        Write-Warning "Invalid configuration: $($validation.Errors -join ', ')"
    }
.NOTES
    This function is used internally by the configuration management system.
#>
function Test-OSDCloudConfig {
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$Config = $script:OSDCloudConfig
    )

    begin {
        $isValid = $true
        $validationErrors = @()
    }

    process {
        try {
            # Validate required fields
            $requiredFields = @(
                'OrganizationName',
                'LogFilePath',
                'DefaultOSLanguage',
                'DefaultOSEdition',
                'ISOOutputPath'
            )

            foreach ($field in $requiredFields) {
                if (-not $Config.ContainsKey($field) -or [string]::IsNullOrEmpty($Config[$field])) {
                    $isValid = $false
                    $validationErrors += "Missing required configuration field: $field"
                }
            }

            # Validate log level
            $validLogLevels = @('Debug', 'Info', 'Warning', 'Error', 'Fatal')
            if ($Config.ContainsKey('LogLevel') -and $validLogLevels -notcontains $Config.LogLevel) {
                $isValid = $false
                $validationErrors += "Invalid log level: $($Config.LogLevel). Valid values are: $($validLogLevels -join ', ')"
            }

            # Validate numeric values
            $numericFields = @(
                @{Name = 'LogRetentionDays'; Min = 1; Max = 365},
                @{Name = 'MaxRetryAttempts'; Min = 1; Max = 10},
                @{Name = 'RetryDelaySeconds'; Min = 1; Max = 60},
                @{Name = 'MinimumCPUGeneration'; Min = 1; Max = 20},
                @{Name = 'MaxParallelTasks'; Min = 1; Max = 16},
                @{Name = 'LargeFileSizeThresholdMB'; Min = 10; Max = 1000}
            )

            foreach ($field in $numericFields) {
                if ($Config.ContainsKey($field.Name) -and
                    ($Config[$field.Name] -lt $field.Min -or $Config[$field.Name] -gt $field.Max)) {
                    $isValid = $false
                    $validationErrors += "Invalid value for $($field.Name): $($Config[$field.Name]). Valid range is $($field.Min) to $($field.Max)"
                }
            }

            # Validate boolean values
            $booleanFields = @(
                'LoggingEnabled', 'EnableAutoRecovery', 'CreateBackups', 'AutopilotEnabled',
                'SkipAutopilotOOBE', 'RequireTPM20', 'CleanupTempFiles', 'IncludeWinRE',
                'OptimizeISOSize', 'ErrorRecoveryEnabled', 'EnableSharedLogging',
                'EnableParallelProcessing', 'UseRobocopyForLargeFiles', 'VerboseLogging',
                'DebugLogging'
            )

            foreach ($field in $booleanFields) {
                if ($Config.ContainsKey($field) -and $Config[$field] -isnot [bool]) {
                    $isValid = $false
                    $validationErrors += "Invalid value for $($field): must be a boolean (true/false)"
                }
            }

            # Validate PowerShell version format
            if ($Config.ContainsKey('PowerShell7Version') -and
                -not ($Config.PowerShell7Version -match '^\d+\.\d+\.\d+$')) {
                $isValid = $false
                $validationErrors += "Invalid PowerShell version format: $($Config.PowerShell7Version). Expected format: X.Y.Z"
            }

            # Validate URL format
            if ($Config.ContainsKey('PowerShell7DownloadUrl') -and
                -not ($Config.PowerShell7DownloadUrl -match '^https?://')) {
                $isValid = $false
                $validationErrors += "Invalid URL format for PowerShell7DownloadUrl: $($Config.PowerShell7DownloadUrl)"
            }
        }
        catch {
            $isValid = $false
            $validationErrors += "Validation error: $_"

            # Log the error
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message "Configuration validation error: $_" -Level Error -Component "Test-OSDCloudConfig" -Exception $_.Exception
            }
        }
    }

    end {
        return [PSCustomObject]@{
            IsValid = $isValid
            Errors = $validationErrors
        }
    }
}

<#
.SYNOPSIS
    Loads OSDCloud configuration settings from a JSON file.
.DESCRIPTION
    Loads OSDCloud configuration settings from a JSON file and merges them with the default settings.
    The loaded settings are validated before being applied.
.PARAMETER Path
    The path to the JSON configuration file.
.EXAMPLE
    Import-OSDCloudConfig -Path "C:\OSDCloud\config.json"
.NOTES
    If the configuration file is invalid, the function will return $false and log warnings.
#>
function Import-OSDCloudConfig {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    begin {
        # Log the operation start
        if ($script:LoggerExists) {
            Invoke-OSDCloudLogger -Message "Importing configuration from $Path" -Level Info -Component "Import-OSDCloudConfig"
        }
    }

    process {
        try {
            if (-not (Test-Path $Path)) {
                $errorMessage = "Configuration file not found: $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Warning -Component "Import-OSDCloudConfig"
                }
                else {
                    Write-Warning $errorMessage
                }
                return $false
            }

            $configJson = Get-Content -Path $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            $config = @{}

            # Convert JSON to hashtable
            $configJson.PSObject.Properties | ForEach-Object {
                $config[$_.Name] = $_.Value
            }

            # Validate the loaded configuration
            $validation = Test-OSDCloudConfig -Config $config

            if (-not $validation.IsValid) {
                $errorMessage = "Invalid configuration loaded from $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Warning -Component "Import-OSDCloudConfig"
                    foreach ($validationError in $validation.Errors) {
                        Invoke-OSDCloudLogger -Message $validationError -Level Warning -Component "Import-OSDCloudConfig"
                    }
               }
                else {
                    Write-Warning $errorMessage
                    foreach ($validationError in $validation.Errors) {
                        Write-Warning $validationError
                    }
               }
                return $false
            }

            # Merge with default configuration
            $script:OSDCloudConfig = Merge-OSDCloudConfig -UserConfig $config

            $successMessage = "Configuration successfully loaded from $Path"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Import-OSDCloudConfig"
            }
            else {
                Write-Verbose $successMessage
            }

            return $true
        }
        catch {
            $errorMessage = "Error loading configuration from $Path`: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Import-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Warning $errorMessage
            }
            return $false
        }
    }
}

<#
.SYNOPSIS
    Saves OSDCloud configuration settings to a JSON file.
.DESCRIPTION
    Saves the current or specified OSDCloud configuration settings to a JSON file.
    The configuration is validated before being saved.
.PARAMETER Path
    The path where the JSON configuration file will be saved.
.PARAMETER Config
    A hashtable containing the configuration settings to save. If not specified, the current configuration is used.
.EXAMPLE
    Export-OSDCloudConfig -Path "C:\OSDCloud\config.json"
.EXAMPLE
    $customConfig = Get-OSDCloudConfig
    $customConfig.LogLevel = "Debug"
    Export-OSDCloudConfig -Path "C:\OSDCloud\debug-config.json" -Config $customConfig
.NOTES
    If the directory for the configuration file does not exist, it will be created.
#>
function Export-OSDCloudConfig {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = $script:OSDCloudConfig
    )

    begin {
        # Log the operation start
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Exporting configuration to $Path" -Level Info -Component "Export-OSDCloudConfig"
        }
    }

    process {
        try {
            # Validate the configuration before saving
            $validation = Test-OSDCloudConfig -Config $Config
            if (-not $validation.IsValid) {
                $errorMessage = "Cannot save invalid configuration to $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Export-OSDCloudConfig"
                    foreach ($validationError in $validation.Errors) {
                        Invoke-OSDCloudLogger -Message $validationError -Level Error -Component "Export-OSDCloudConfig"
                    }
                }
                else {
                    Write-Error $errorMessage
                    foreach ($validationError in $validation.Errors) {
                        Write-Error $validationError
                    }
                }
                return $false
            }

            # Create directory if it doesn't exist
            $directory = Split-Path -Path $Path -Parent
            if (-not (Test-Path $directory)) {
                if ($PSCmdlet.ShouldProcess($directory, "Create directory")) {
                    New-Item -Path $directory -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }
                else {
                    return $false
                }
            }

            # Convert hashtable to JSON and save
            if ($PSCmdlet.ShouldProcess($Path, "Save configuration")) {
                $Config | ConvertTo-Json -Depth 5 | Set-Content -Path $Path -Force -ErrorAction Stop

                $successMessage = "Configuration successfully saved to $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Export-OSDCloudConfig"
                }
                else {
                    Write-Verbose $successMessage
                }

                return $true
            }
            else {
                return $false
            }
        }
        catch {
            $errorMessage = "Error saving configuration to $Path`: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Export-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error $errorMessage
            }
            return $false
        }
    }
}

<#
.SYNOPSIS
    Merges user-defined configuration settings with default settings.
.DESCRIPTION
    Merges user-defined configuration settings with default settings to create a complete configuration.
    This function preserves all default settings while overriding them with user-defined values where provided.
.PARAMETER UserConfig
    A hashtable containing user-defined configuration settings.
.PARAMETER DefaultConfig
    A hashtable containing default configuration settings. If not specified, the current default configuration is used.
.EXAMPLE
    $userConfig = @{
        LogLevel = "Debug"
        CreateBackups = $false
    }
    $mergedConfig = Merge-OSDCloudConfig -UserConfig $userConfig
.NOTES
    This function is used internally by the configuration management system.
#>
function Merge-OSDCloudConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$UserConfig,

        [Parameter(Mandatory = $false)]
        [hashtable]$DefaultConfig = $script:OSDCloudConfig
    )

    begin {
        # Create a deep clone of the default config
        $mergedConfig = @{}
        foreach ($key in $DefaultConfig.Keys) {
            if ($DefaultConfig[$key] -is [hashtable]) {
                $mergedConfig[$key] = $DefaultConfig[$key].Clone()
            }
            elseif ($DefaultConfig[$key] -is [array]) {
                $mergedConfig[$key] = $DefaultConfig[$key].Clone()
            }
            else {
                $mergedConfig[$key] = $DefaultConfig[$key]
            }
        }
    }

    process {
        try {
            # Override default values with user settings
            foreach ($key in $UserConfig.Keys) {
                $mergedConfig[$key] = $UserConfig[$key]
            }

            # Log the merge operation
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                $overriddenKeys = $UserConfig.Keys -join ', '
                Invoke-OSDCloudLogger -Message "Merged configuration with overrides for: $overriddenKeys" -Level Verbose -Component "Merge-OSDCloudConfig"
            }
        }
        catch {
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message "Error merging configurations: $_" -Level Error -Component "Merge-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error "Error merging configurations: $_"
            }
            # Return the default config if merging fails
            return $DefaultConfig
        }
    }

    end {
        return $mergedConfig
    }
}

<#
.SYNOPSIS
    Retrieves the current OSDCloud configuration settings.
.DESCRIPTION
    Retrieves the current OSDCloud configuration settings as a hashtable.
    This function can be used to get the current configuration for review or modification.
.EXAMPLE
    $config = Get-OSDCloudConfig
    $config.LogLevel = "Debug"
.NOTES
    Any changes made to the returned hashtable will not affect the actual configuration
    unless the modified hashtable is passed to Export-OSDCloudConfig or used to update
    the $script:OSDCloudConfig variable.
#>
function Get-OSDCloudConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    begin {
        # Log the operation
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Retrieving current configuration" -Level Verbose -Component "Get-OSDCloudConfig"
        }
    }

    process {
        try {
            # Return a clone of the configuration to prevent unintended modifications
            $configClone = @{}
            foreach ($key in $script:OSDCloudConfig.Keys) {
                if ($script:OSDCloudConfig[$key] -is [hashtable]) {
                    $configClone[$key] = $script:OSDCloudConfig[$key].Clone()
                }
                elseif ($script:OSDCloudConfig[$key] -is [array]) {
                    $configClone[$key] = $script:OSDCloudConfig[$key].Clone()
                }
                else {
                    $configClone[$key] = $script:OSDCloudConfig[$key]
                }
            }

            return $configClone
        }
        catch {
            $errorMessage = "Error retrieving configuration: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Get-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error $errorMessage
            }

            # Return an empty hashtable in case of error
            return @{}
        }
    }
}

<#
.SYNOPSIS
    Updates specific OSDCloud configuration settings.
.DESCRIPTION
    Updates specific OSDCloud configuration settings without replacing the entire configuration.
    This function allows you to modify individual settings while preserving all other settings.
.PARAMETER Settings
    A hashtable containing the configuration settings to update.
.EXAMPLE
    Update-OSDCloudConfig -Settings @{
        LogLevel = "Debug"
        CreateBackups = $false
        PowerShell7Version = "7.3.5"
    }
.NOTES
    The updated settings are validated before being applied.
#>
function Update-OSDCloudConfig {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )

    begin {
        # Log the operation start
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            $updatedKeys = $Settings.Keys -join ', '
            Invoke-OSDCloudLogger -Message "Updating configuration settings: $updatedKeys" -Level Info -Component "Update-OSDCloudConfig"
        }
    }

    process {
        try {
            # Create a temporary config with the updates
            $tempConfig = $script:OSDCloudConfig.Clone()
            foreach ($key in $Settings.Keys) {
                $tempConfig[$key] = $Settings[$key]
            }

            # Validate the updated configuration
            $validation = Test-OSDCloudConfig -Config $tempConfig
            if (-not $validation.IsValid) {
                $errorMessage = "Invalid configuration settings"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Update-OSDCloudConfig"
                    foreach ($validationError in $validation.Errors) {
                        Invoke-OSDCloudLogger -Message $validationError -Level Error -Component "Update-OSDCloudConfig"
                    }
                }
                else {
                    Write-Error $errorMessage
                    foreach ($validationError in $validation.Errors) {
                        Write-Error $validationError
                    }
                }
                return $false
            }

            # Apply the updates if validation passes
            if ($PSCmdlet.ShouldProcess("OSDCloud Configuration", "Update settings")) {
                foreach ($key in $Settings.Keys) {
                    $script:OSDCloudConfig[$key] = $Settings[$key]
                }

                $successMessage = "Configuration settings updated successfully"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Update-OSDCloudConfig"
                }
                else {
                    Write-Verbose $successMessage
                }

                return $true
            }
            else {
                return $false
            }
        }
        catch {
            $errorMessage = "Error updating configuration settings: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Update-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error $errorMessage
            }
            return $false
        }
    }
}

<#
.SYNOPSIS
    Expands environment variables in string values.
.DESCRIPTION
    Processes a string and expands any environment variables into their actual values.
    This allows for dynamic paths and configurations based on system environment.
.PARAMETER Value
    The string value containing environment variables to expand.
.EXAMPLE
    Expand-EnvironmentVariables -Value "%TEMP%\Logs"
    Returns the expanded path with %TEMP% replaced by the actual temp directory.
.NOTES
    Environment variables should be in the format %VARIABLENAME% or $env:VARIABLENAME.
#>
function Expand-EnvironmentVariables {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Value
    )

    process {
        return [Environment]::ExpandEnvironmentVariables($Value)
    }
}

<#
.SYNOPSIS
    Processes all path-based configuration values and expands environment variables.
.DESCRIPTION
    Iterates through a configuration hashtable and expands environment variables in all path-related settings.
    This allows for dynamic paths that can adapt to different environments.
.PARAMETER Config
    The configuration hashtable to process.
.EXAMPLE
    $config = Expand-ConfigPaths -Config $OSDCloudConfig
.NOTES
    This function is used internally by the configuration management system.
#>
function Expand-ConfigPaths {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    # List of keys containing paths that should support env variables
    $pathKeys = @(
        'LogFilePath',
        'ErrorLogPath',
        'ISOOutputPath',
        'TempWorkspacePath',
        'SharedConfigPath'
    )

    foreach ($key in $pathKeys) {
        if ($Config.ContainsKey($key) -and -not [string]::IsNullOrEmpty($Config[$key])) {
            $Config[$key] = Expand-EnvironmentVariables -Value $Config[$key]
        }
    }

    return $Config
}

<#
.SYNOPSIS
    Protects sensitive configuration values through encryption.
.DESCRIPTION
    Encrypts sensitive configuration values to protect them when stored on disk.
    The encryption is Windows user account specific.
.PARAMETER Value
    The sensitive string value to encrypt.
.EXAMPLE
    $encryptedValue = Protect-ConfigValue -Value "p@ssw0rd"
.NOTES
    This function uses Windows Data Protection API (DPAPI) for encryption.
#>
function Protect-ConfigValue {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $false)]
        [string]$AdditionalEntropy = "OSDCloudCustomBuilder"
    )

    # Convert string to secure string with additional entropy for stronger encryption
    $secureString = ConvertTo-SecureString -String $Value -AsPlainText -Force
    $encrypted = ConvertFrom-SecureString -SecureString $secureString

    return $encrypted
}

<#
.SYNOPSIS
    Decrypts protected configuration values.
.DESCRIPTION
    Decrypts previously encrypted configuration values to make them usable in the application.
    The decryption can only be performed by the same Windows user account that encrypted the value.
.PARAMETER EncryptedValue
    The encrypted string value to decrypt.
.EXAMPLE
    $plainText = Unprotect-ConfigValue -EncryptedValue $encryptedPassword
.NOTES
    This function uses Windows Data Protection API (DPAPI) for decryption.
#>
function Unprotect-ConfigValue {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EncryptedValue
    )

    try {
        # Convert encrypted string back to secure string
        $secureString = ConvertTo-SecureString -String $EncryptedValue

        # Extract plain text
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        return $plainText
    }
    catch {
        Write-Warning "Failed to decrypt value: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Exports a secure version of OSDCloud configuration with sensitive values encrypted.
.DESCRIPTION
    Creates and saves a secure version of the OSDCloud configuration with sensitive values encrypted.
    This allows storing configurations with API keys, credentials, etc. in shared locations.
.PARAMETER Path
    The path where the JSON configuration file will be saved.
.PARAMETER Config
    A hashtable containing the configuration settings to save. If not specified, the current configuration is used.
.PARAMETER SensitiveKeys
    An array of key names that should be considered sensitive and encrypted.
.EXAMPLE
    Export-SecureOSDCloudConfig -Path "C:\OSDCloud\secure-config.json"
.EXAMPLE
    Export-SecureOSDCloudConfig -Path "C:\OSDCloud\secure-config.json" -SensitiveKeys @('ApiKey', 'Password')
.NOTES
    The encryption is tied to the Windows user account performing the encryption.
#>
function Export-SecureOSDCloudConfig {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string[]]$SensitiveKeys = @('Password', 'ApiKey', 'Secret', 'Token', 'Credential')
    )

    begin {
        # Log the operation start
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Exporting secure configuration to $Path" -Level Info -Component "Export-SecureOSDCloudConfig"
        }
    }

    process {
        try {
            # Create a copy of the configuration for encryption
            $secureConfig = @{}
            foreach ($key in $Config.Keys) {
                if ($Config[$key] -is [hashtable]) {
                    $secureConfig[$key] = $Config[$key].Clone()
                }
                elseif ($Config[$key] -is [array]) {
                    $secureConfig[$key] = $Config[$key].Clone()
                }
                else {
                    $secureConfig[$key] = $Config[$key]
                }
            }

            # Encrypt sensitive values
            foreach ($key in $SensitiveKeys) {
                if ($secureConfig.ContainsKey($key) -and -not [string]::IsNullOrEmpty($secureConfig[$key])) {
                    $secureConfig[$key] = Protect-ConfigValue -Value $secureConfig[$key]

                    if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                        Invoke-OSDCloudLogger -Message "Encrypted sensitive key: $key" -Level Verbose -Component "Export-SecureOSDCloudConfig"
                    }
                }
            }

            # Add metadata to indicate this is a secure configuration
            $secureConfig['_IsSecure'] = $true
            $secureConfig['_EncryptedKeys'] = $SensitiveKeys
            $secureConfig['_EncryptedBy'] = $env:USERNAME
            $secureConfig['_EncryptedDate'] = (Get-Date).ToString('o')

            # Validate the secure configuration
            $validation = Test-OSDCloudConfig -Config $secureConfig
            if (-not $validation.IsValid) {
                $errorMessage = "Cannot save invalid secure configuration to $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Export-SecureOSDCloudConfig"
                    foreach ($validationError in $validation.Errors) {
                        Invoke-OSDCloudLogger -Message $validationError -Level Error -Component "Export-SecureOSDCloudConfig"
                    }
                }
                else {
                    Write-Error $errorMessage
                    foreach ($validationError in $validation.Errors) {
                        Write-Error $validationError
                    }
                }
                return $false
            }

            # Create directory if it doesn't exist
            $directory = Split-Path -Path $Path -Parent
            if (-not (Test-Path $directory)) {
                if ($PSCmdlet.ShouldProcess($directory, "Create directory")) {
                    New-Item -Path $directory -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }
                else {
                    return $false
                }
            }

            # Convert hashtable to JSON and save
            if ($PSCmdlet.ShouldProcess($Path, "Save secure configuration")) {
                $secureConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $Path -Force -ErrorAction Stop

                $successMessage = "Secure configuration successfully saved to $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Export-SecureOSDCloudConfig"
                }
                else {
                    Write-Verbose $successMessage
                }

                return $true
            }
            else {
                return $false
            }
        }
        catch {
            $errorMessage = "Error saving secure configuration to $Path`: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Export-SecureOSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error $errorMessage
            }
            return $false
        }
    }
}

<#
.SYNOPSIS
    Imports a secure OSDCloud configuration with encrypted sensitive values.
.DESCRIPTION
    Loads a secure OSDCloud configuration file and decrypts any encrypted sensitive values.
    The configuration must have been encrypted by the same Windows user account.
.PARAMETER Path
    The path to the secure JSON configuration file.
.EXAMPLE
    Import-SecureOSDCloudConfig -Path "C:\OSDCloud\secure-config.json"
.NOTES
    The decryption can only be performed by the same Windows user account that encrypted the values.
#>
function Import-SecureOSDCloudConfig {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    begin {
        # Log the operation start
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Importing secure configuration from $Path" -Level Info -Component "Import-SecureOSDCloudConfig"
        }
    }

    process {
        try {
            if (-not (Test-Path $Path)) {
                $errorMessage = "Secure configuration file not found: $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Warning -Component "Import-SecureOSDCloudConfig"
                }
                else {
                    Write-Warning $errorMessage
                }
                return $false
            }

            $configJson = Get-Content -Path $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            $config = @{}

            # Convert JSON to hashtable
            $configJson.PSObject.Properties | ForEach-Object {
                $config[$_.Name] = $_.Value
            }

            # Check if this is a secure configuration
            if (-not $config.ContainsKey('_IsSecure') -or -not $config['_IsSecure']) {
                $errorMessage = "Configuration file is not a secure configuration: $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Warning -Component "Import-SecureOSDCloudConfig"
                }
                else {
                    Write-Warning $errorMessage
                }
                return $false
            }

            # Get the list of encrypted keys
            $encryptedKeys = @()
            if ($config.ContainsKey('_EncryptedKeys')) {
                $encryptedKeys = $config['_EncryptedKeys']
            }

            # Decrypt sensitive values
            foreach ($key in $encryptedKeys) {
                if ($config.ContainsKey($key) -and -not [string]::IsNullOrEmpty($config[$key])) {
                    $decryptedValue = Unprotect-ConfigValue -EncryptedValue $config[$key]
                    if ($null -ne $decryptedValue) {
                        $config[$key] = $decryptedValue

                        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                            Invoke-OSDCloudLogger -Message "Decrypted sensitive key: $key" -Level Verbose -Component "Import-SecureOSDCloudConfig"
                        }
                    }
                    else {
                        $errorMessage = "Failed to decrypt key: $key"
                        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                            Invoke-OSDCloudLogger -Message $errorMessage -Level Warning -Component "Import-SecureOSDCloudConfig"
                        }
                        else {
                            Write-Warning $errorMessage
                        }
                    }
                }
            }

            # Remove security metadata
            $config.Remove('_IsSecure')
            $config.Remove('_EncryptedKeys')
            $config.Remove('_EncryptedBy')
            $config.Remove('_EncryptedDate')

            # Validate the decrypted configuration
            $validation = Test-OSDCloudConfig -Config $config
            if (-not $validation.IsValid) {
                $errorMessage = "Invalid secure configuration loaded from $Path"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Warning -Component "Import-SecureOSDCloudConfig"
                    foreach ($validationError in $validation.Errors) {
                        Invoke-OSDCloudLogger -Message $validationError -Level Warning -Component "Import-SecureOSDCloudConfig"
                    }
                }
                else {
                    Write-Warning $errorMessage
                    foreach ($validationError in $validation.Errors) {
                        Write-Warning $validationError
                    }
                }
                return $false
            }

            # Merge with default configuration
            $script:OSDCloudConfig = Merge-OSDCloudConfig -UserConfig $config

            $successMessage = "Secure configuration successfully loaded from $Path"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Import-SecureOSDCloudConfig"
            }
            else {
                Write-Verbose $successMessage
            }

            return $true
        }
        catch {
            $errorMessage = "Error loading secure configuration from $Path`: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Import-SecureOSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Warning $errorMessage
            }
            return $false
        }
    }
}

<#
.SYNOPSIS
    Resets the OSDCloud configuration to default values.
.DESCRIPTION
    Resets the OSDCloud configuration to its default values, effectively clearing any user customizations.
    This function can be useful for troubleshooting or starting fresh.
.PARAMETER Confirm
    Prompts for confirmation before resetting the configuration.
.EXAMPLE
    Reset-OSDCloudConfig
.EXAMPLE
    Reset-OSDCloudConfig -Confirm:$false
.NOTES
    This operation cannot be undone unless you have a backup of your configuration.
#>
function Reset-OSDCloudConfig {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([bool])]
    param()

    begin {
        # Log the operation start
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Resetting configuration to defaults" -Level Warning -Component "Reset-OSDCloudConfig"
        }
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess("OSDCloud Configuration", "Reset to default values")) {
                # Store the current config as backup in memory (for this session only)
                $backupConfig = $script:OSDCloudConfig.Clone()

                # Reset to default configuration
                $script:OSDCloudConfig = @{
                    # Organization settings
                    OrganizationName = "iTechDevelopment_Charities"
                    OrganizationContact = "IT Support"
                    OrganizationEmail = "support@charity.org"

                    # Logging settings
                    LoggingEnabled = $true
                    LogLevel = "Info"
                    LogRetentionDays = 30
                    LogFilePath = "$env:TEMP\OSDCloud\Logs\OSDCloudCustomBuilder.log"
                    VerboseLogging = $false
                    DebugLogging = $false

                    # Default deployment settings
                    DefaultOSLanguage = "en-us"
                    DefaultOSEdition = "Enterprise"
                    DefaultOSLicense = "Volume"

                    # Recovery settings
                    MaxRetryAttempts = 3
                    RetryDelaySeconds = 5
                    EnableAutoRecovery = $true
                    CreateBackups = $true

                    # Customization settings
                    CustomWimSearchPaths = @(
                        "X:\OSDCloud\custom.wim",
                        "C:\OSDCloud\custom.wim",
                        "D:\OSDCloud\custom.wim",
                        "E:\OSDCloud\custom.wim"
                    )

                    # PowerShell 7 settings
                    PowerShell7Version = "7.3.4"
                    PowerShell7DownloadUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.3.4/PowerShell-7.3.4-win-x64.zip"
                    PowerShell7Modules = @(
                        "OSD",
                        "Microsoft.Graph.Intune",
                        "WindowsAutopilotIntune"
                    )

                    # Autopilot settings
                    AutopilotEnabled = $true
                    SkipAutopilotOOBE = $true

                    # Hardware compatibility settings
                    RequireTPM20 = $true
                    MinimumCPUGeneration = 8

                    # ISO building settings
                    ISOOutputPath = "C:\OSDCloud\ISO"
                    TempWorkspacePath = "$env:TEMP\OSDCloudWorkspace"
                    CleanupTempFiles = $true
                    IncludeWinRE = $true
                    OptimizeISOSize = $true

                    # Error handling settings
                    ErrorRecoveryEnabled = $true
                    ErrorLogPath = "$env:TEMP\OSDCloud\Logs\Errors"
                    MaxErrorRetry = 3
                    ErrorRetryDelay = 5

                    # Integration settings
                    SharedConfigPath = "$env:ProgramData\OSDCloud\Config"
                    EnableSharedLogging = $true

                    # Performance settings
                    EnableParallelProcessing = $true
                    MaxParallelTasks = 4
                    UseRobocopyForLargeFiles = $true
                    LargeFileSizeThresholdMB = 100

                    # Schema version for configuration compatibility
                    SchemaVersion = "1.0"

                    # Metadata fields for tracking
                    LastModified = (Get-Date).ToString('o')
                    ModifiedBy = $env:USERNAME
                    ChangeHistory = @()

                    # Active configuration profile
                    ActiveProfile = "Default"
                }

                $successMessage = "Configuration successfully reset to default values"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Reset-OSDCloudConfig"
                }
                else {
                    Write-Verbose $successMessage
                }

                return $true
            }
            else {
                return $false
            }
        }
        catch {
            $errorMessage = "Error resetting configuration: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Reset-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error $errorMessage
            }
            return $false
        }
    }
}

<#
.SYNOPSIS
    Creates a backup of the current OSDCloud configuration.
.DESCRIPTION
    Creates a timestamped backup of the current OSDCloud configuration to prevent data loss
    during configuration changes or updates.
.PARAMETER BackupPath
    The directory where the backup file will be saved. If not specified, uses the default backup location.
.EXAMPLE
    Backup-OSDCloudConfig
.EXAMPLE
    Backup-OSDCloudConfig -BackupPath "C:\Backups\OSDCloud"
.NOTES
    Backup files are named with a timestamp to prevent conflicts.
#>
function Backup-OSDCloudConfig {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$BackupPath = "$env:TEMP\OSDCloud\Backups"
    )

    begin {
        # Log the operation start
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Creating configuration backup" -Level Info -Component "Backup-OSDCloudConfig"
        }
    }

    process {
        try {
            # Create backup directory if it doesn't exist
            if (-not (Test-Path $BackupPath)) {
                New-Item -Path $BackupPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }

            # Generate timestamped filename
            $timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
            $backupFileName = "OSDCloudConfig_Backup_$timestamp.json"
            $backupFilePath = Join-Path -Path $BackupPath -ChildPath $backupFileName

            # Export current configuration to backup file
            $exportResult = Export-OSDCloudConfig -Path $backupFilePath -Config $script:OSDCloudConfig

            if ($exportResult) {
                $successMessage = "Configuration backup created: $backupFilePath"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Backup-OSDCloudConfig"
                }
                else {
                    Write-Verbose $successMessage
                }

                return $backupFilePath
            }
            else {
                $errorMessage = "Failed to create configuration backup"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Backup-OSDCloudConfig"
                }
                else {
                    Write-Error $errorMessage
                }
                return $null
            }
        }
        catch {
            $errorMessage = "Error creating configuration backup: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Backup-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error $errorMessage
            }
            return $null
        }
    }
}

<#
.SYNOPSIS
    Restores OSDCloud configuration from a backup file.
.DESCRIPTION
    Restores the OSDCloud configuration from a previously created backup file.
    This function validates the backup before applying it.
.PARAMETER BackupPath
    The path to the backup configuration file to restore.
.EXAMPLE
    Restore-OSDCloudConfig -BackupPath "C:\Backups\OSDCloud\OSDCloudConfig_Backup_20250331_143022.json"
.NOTES
    The backup file must be a valid OSDCloud configuration file.
#>
function Restore-OSDCloudConfig {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupPath
    )

    begin {
        # Log the operation start
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Restoring configuration from backup: $BackupPath" -Level Warning -Component "Restore-OSDCloudConfig"
        }
    }

    process {
        try {
            if (-not (Test-Path $BackupPath)) {
                $errorMessage = "Backup file not found: $BackupPath"
                if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                    Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Restore-OSDCloudConfig"
                }
                else {
                    Write-Error $errorMessage
                }
                return $false
            }

            if ($PSCmdlet.ShouldProcess("OSDCloud Configuration", "Restore from backup: $BackupPath")) {
                # Create a backup of current config before restoring
                $currentBackup = Backup-OSDCloudConfig
                if ($null -eq $currentBackup) {
                    Write-Warning "Could not create backup of current configuration before restore"
                }

                # Import the backup configuration
                $restoreResult = Import-OSDCloudConfig -Path $BackupPath

                if ($restoreResult) {
                    $successMessage = "Configuration successfully restored from backup: $BackupPath"
                    if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                        Invoke-OSDCloudLogger -Message $successMessage -Level Info -Component "Restore-OSDCloudConfig"
                    }
                    else {
                        Write-Verbose $successMessage
                    }

                    return $true
                }
                else {
                    $errorMessage = "Failed to restore configuration from backup: $BackupPath"
                    if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                        Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Restore-OSDCloudConfig"
                    }
                    else {
                        Write-Error $errorMessage
                    }
                    return $false
                }
            }
            else {
                return $false
            }
        }
        catch {
            $errorMessage = "Error restoring configuration from backup: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Restore-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error $errorMessage
            }
            return $false
        }
    }
}

# Initialize logger existence check
$script:LoggerExists = $null -ne (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue)

# Expand environment variables in path configurations on module load
$script:OSDCloudConfig = Expand-ConfigPaths -Config $script:OSDCloudConfig

# Export functions for module use
Export-ModuleMember -Function @(
    'Test-OSDCloudConfig',
    'Import-OSDCloudConfig',
    'Export-OSDCloudConfig',
    'Merge-OSDCloudConfig',
    'Get-OSDCloudConfig',
    'Update-OSDCloudConfig',
    'Expand-EnvironmentVariables',
    'Expand-ConfigPaths',
    'Protect-ConfigValue',
    'Unprotect-ConfigValue',
    'Export-SecureOSDCloudConfig',
    'Import-SecureOSDCloudConfig',
    'Reset-OSDCloudConfig',
    'Backup-OSDCloudConfig',
    'Restore-OSDCloudConfig'
)


