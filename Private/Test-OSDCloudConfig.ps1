# Function: Test-OSDCloudConfig
# Author: Oluwaseun Fayese
# Company: Modern Endpoint Management
# Last Modified: April 19, 2025

<#
.SYNOPSIS
    Validates the OSDCloudCustomBuilder module configuration.
.DESCRIPTION
    This function validates the configuration settings for the OSDCloudCustomBuilder module,
    ensuring that all required fields are present and that values are of the correct type.
    It returns a validation result object with information about any validation errors.
.PARAMETER Config
    The configuration to validate.
.EXAMPLE
    Test-OSDCloudConfig -Config $config
.NOTES
    This function is used internally by other module functions.
#>
function Test-OSDCloudConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config = $script:OSDCloudConfig
    )
    
    process {
        try {
            $result = @{
                IsValid = $true
                Errors = @()
            }
            
            # Check for required sections
            $requiredSections = @("PowerShell7", "Paths", "Timeouts", "Telemetry")
            foreach ($section in $requiredSections) {
                if (-not $Config.ContainsKey($section)) {
                    $result.IsValid = $false
                    $result.Errors += "Missing required section: $section"
                }
            }
            
            # Check for required fields
            $requiredFields = @(
                @{ Section = "PowerShell7"; Field = "Version" },
                @{ Section = "PowerShell7"; Field = "CacheEnabled" },
                @{ Section = "Paths"; Field = "WorkingDirectory" },
                @{ Section = "Paths"; Field = "Cache" },
                @{ Section = "Paths"; Field = "Logs" },
                @{ Section = "Timeouts"; Field = "Download" },
                @{ Section = "Timeouts"; Field = "Mount" },
                @{ Section = "Timeouts"; Field = "Dismount" },
                @{ Section = "Timeouts"; Field = "Job" },
                @{ Section = "Telemetry"; Field = "Enabled" },
                @{ Section = "Telemetry"; Field = "Path" },
                @{ Section = "Telemetry"; Field = "RetentionDays" }
            )
            
            foreach ($field in $requiredFields) {
                if ($Config.ContainsKey($field.Section) -and -not $Config[$field.Section].ContainsKey($field.Field)) {
                    $result.IsValid = $false
                    $result.Errors += "Missing required field: $($field.Section).$($field.Field)"
                }
            }
            
            # Check numeric fields
            $numericFields = @(
                @{ Section = "Timeouts"; Field = "Download" },
                @{ Section = "Timeouts"; Field = "Mount" },
                @{ Section = "Timeouts"; Field = "Dismount" },
                @{ Section = "Timeouts"; Field = "Job" },
                @{ Section = "Telemetry"; Field = "RetentionDays" }
            )
            
            foreach ($field in $numericFields) {
                if ($Config.ContainsKey($field.Section) -and $Config[$field.Section].ContainsKey($field.Field)) {
                    $value = $Config[$field.Section][$field.Field]
                    if (-not ($value -is [int] -or $value -is [long] -or $value -is [double])) {
                        $result.IsValid = $false
                        $result.Errors += "Field $($field.Section).$($field.Field) must be a number (found: $($value.GetType().Name))"
                    }
                }
            }
            
            # Check boolean fields
            $booleanFields = @(
                @{ Section = "PowerShell7"; Field = "CacheEnabled" },
                @{ Section = "Telemetry"; Field = "Enabled" },
                @{ Section = "Telemetry"; Field = "AnonymizeHostname" },
                @{ Section = "Telemetry"; Field = "IncludeSystemInfo" }
            )
            
            foreach ($field in $booleanFields) {
                if ($Config.ContainsKey($field.Section) -and $Config[$field.Section].ContainsKey($field.Field)) {
                    $value = $Config[$field.Section][$field.Field]
                    if (-not ($value -is [bool])) {
                        $result.IsValid = $false
                        $result.Errors += "Field $($field.Section).$($field.Field) must be a boolean (found: $($value.GetType().Name))"
                    }
                }
            }
            
            return $result
        }
        catch {
            return @{
                IsValid = $false
                Errors = @("Validation error: $_")
            }
        }
    }
}

Export-ModuleMember -Function Test-OSDCloudConfig