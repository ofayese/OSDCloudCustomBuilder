# Function: Add-ConfigChangeRecord
# Author: Oluwaseun Fayese
# Company: Modern Endpoint Management
# Last Modified: April 19, 2025

<#
.SYNOPSIS
    Adds a record of configuration changes to the module's change log.
.DESCRIPTION
    This function records changes made to the module configuration, including
    who made the change, when it was made, and what was changed. This helps
    with auditing and troubleshooting configuration issues.
.PARAMETER Config
    The configuration that was changed.
.PARAMETER Action
    The action that was performed (e.g., "Update", "Reset").
.EXAMPLE
    Add-ConfigChangeRecord -Config $config -Action "Update"
.NOTES
    This function is used internally by other module functions.
#>
function Add-ConfigChangeRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        
        [Parameter()]
        [ValidateSet("Update", "Reset")]
        [string]$Action = "Update"
    )
    
    process {
        try {
            # Create a change record
            $changeRecord = @{
                Timestamp = Get-Date
                Action = $Action
                User = $env:USERNAME
                ComputerName = $env:COMPUTERNAME
                ConfigSections = $Config.Keys -join ", "
            }
            
            # Get the path to the change log
            $changeLogPath = Join-Path -Path $script:ModuleRoot -ChildPath "config.changes.json"
            
            # Load existing change records
            $changeRecords = @()
            if (Test-Path -Path $changeLogPath) {
                $changeRecords = Get-Content -Path $changeLogPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
                if (-not $changeRecords) {
                    $changeRecords = @()
                }
            }
            
            # Add the new record
            $changeRecords += $changeRecord
            
            # Keep only the last 100 records
            if ($changeRecords.Count -gt 100) {
                $changeRecords = $changeRecords | Select-Object -Last 100
            }
            
            # Save the change records
            $changeRecords | ConvertTo-Json -Depth 10 | Set-Content -Path $changeLogPath -Force
            Write-Verbose "Added configuration change record to $changeLogPath"
        }
        catch {
            Write-Warning "Failed to add configuration change record: $_"
        }
    }
}

Export-ModuleMember -Function Add-ConfigChangeRecord