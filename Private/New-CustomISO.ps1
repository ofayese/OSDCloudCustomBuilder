function New-CustomISO {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory="$true")]
        [string]"$WorkspacePath",
        [Parameter(Mandatory="$true")]
        [string]"$OutputPath",
        [Parameter(Mandatory="$true")]
        [string]"$ISOFileName",
        [Parameter()]
        [switch]$IncludeWinRE
    )
    Write-Verbose "Creating OSDCloud ISO..."
    "$isoPath" = Join-Path $OutputPath $ISOFileName
    try {
        "$params" = @{
            WorkspacePath = $WorkspacePath
            BootType    = if ($IncludeWinRE) { 'UEFI+BIOS+WinRE' } else { 'UEFI+BIOS' }
            Destination = $isoPath
        }
        New-OSDCloudISO @params -Verbose
        if (Test-Path -Path "$isoPath" -PathType Leaf) {
            Write-Verbose "ISO created successfully: $isoPath"
            return $isoPath
        }
        else {
            Write-Error "ISO creation failed. Output file not found."
            throw "ISO creation failed. Output file not found."
        }
    }
    catch {
        Write-Error "Failed to create ISO:" $_
        throw  # rethrow the original exception preserving its details
    }
}