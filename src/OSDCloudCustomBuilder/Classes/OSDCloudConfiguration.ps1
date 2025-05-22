using namespace System.Management.Automation
using namespace System.Collections.Generic

class OSDCloudConfiguration {
    [string]$OrganizationName
    [string]$OrganizationContact
    [string]$OrganizationEmail
    [bool]$LoggingEnabled
    [string]$LogLevel
    [int]$LogRetentionDays
    [string]$LogFilePath
    [bool]$VerboseLogging
    [bool]$DebugLogging
    [string]$DefaultOSLanguage
    [string]$DefaultOSEdition
    [string]$DefaultOSLicense
    [string]$SchemaVersion
    [datetime]$LastModified
    [string]$ModifiedBy
    [List[hashtable]]$ChangeHistory

    OSDCloudConfiguration() {
        $this.InitializeDefaults()
    }

    hidden [void] InitializeDefaults() {
        $this.LoggingEnabled = $true
        $this.LogLevel = "Info"
        $this.LogRetentionDays = 30
        $this.LogFilePath = Join-Path $env:TEMP "OSDCloud\Logs\OSDCloudCustomBuilder.log"
        $this.SchemaVersion = "1.0"
        $this.LastModified = Get-Date
        $this.ModifiedBy = $env:USERNAME
        $this.ChangeHistory = [List[hashtable]]::new()
    }

    [hashtable] ToHashtable() {
        $hash = @{}
        $this | Get-Member -MemberType Property | ForEach-Object {
            $hash[$_.Name] = $this.$($_.Name)
        }
        return $hash
    }

    [void] LoadFromHashtable([hashtable]$hash) {
        foreach ($key in $hash.Keys) {
            if ($this | Get-Member -Name $key -MemberType Property) {
                $this.$key = $hash[$key]
            }
        }
    }

    [void] AddChangeRecord([string]$change, [string]$reason) {
        $record = @{
            Timestamp = Get-Date
            User = $env:USERNAME
            Change = $change
            Reason = $reason
        }
        $this.ChangeHistory.Insert(0, $record)

        # Keep only last 10 changes
        while ($this.ChangeHistory.Count -gt 10) {
            $this.ChangeHistory.RemoveAt($this.ChangeHistory.Count - 1)
        }
    }
}
