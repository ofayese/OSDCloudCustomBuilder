# Invoke-Cleanup.ps1
# Provides cleanup functions for OSDCloudCustomBuilder tests

function Invoke-Cleanup {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$Paths,

        [Parameter()]
        [switch]$Force
    )

    foreach ($path in $Paths) {
        if (Test-Path -Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                Write-Verbose "Successfully removed: $path"
            }
            catch {
                Write-Warning "Failed to remove $path: $_"

                if ($Force) {
                    try {
                        # Try alternative cleanup methods for stubborn files
                        if (Test-Path -Path $path -PathType Leaf) {
                            # For files, try using .NET methods
                            [System.IO.File]::Delete($path)
                        }
                        else {
                            # For directories, try to remove read-only attributes first
                            Get-ChildItem -Path $path -Recurse -Force |
                                Where-Object { -not $_.PSIsContainer } |
                                ForEach-Object { $_.Attributes = 'Normal' }

                            # Then try removal again
                            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                        }

                        Write-Verbose "Successfully removed with force method: $path"
                    }
                    catch {
                        Write-Warning "Failed to force remove $path: $_"
                    }
                }
            }
        }
        else {
            Write-Verbose "Path not found, skipping: $path"
        }
    }
}

function Dismount-TestWimImage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MountPath,

        [Parameter()]
        [switch]$SaveChanges,

        [Parameter()]
        [switch]$Force
    )

    # Check if the mount path exists
    if (-not (Test-Path -Path $MountPath)) {
        Write-Verbose "Mount path not found, nothing to dismount: $MountPath"
        return $true
    }

    # Check if DISM cmdlets are available
    if (Get-Command -Name Dismount-WindowsImage -ErrorAction SilentlyContinue) {
        try {
            $params = @{
                Path = $MountPath
                Discard = (-not $SaveChanges)
            }

            Dismount-WindowsImage @params -ErrorAction Stop
            Write-Verbose "Successfully dismounted image from: $MountPath"
            return $true
        }
        catch {
            Write-Warning "Failed to dismount image: $_"

            if ($Force) {
                try {
                    # Try with force parameter
                    Dismount-WindowsImage -Path $MountPath -Discard -Force -ErrorAction Stop
                    Write-Verbose "Successfully force dismounted image from: $MountPath"
                    return $true
                }
                catch {
                    Write-Warning "Failed to force dismount image: $_"
                }
            }
        }
    }
    else {
        Write-Warning "Dismount-WindowsImage cmdlet not available"
    }

    # If we get here, dismounting failed or cmdlet not available
    # Try to clean up the directory anyway
    try {
        Invoke-Cleanup -Paths $MountPath -Force:$Force
        return $true
    }
    catch {
        Write-Warning "Failed to clean up mount path: $_"
        return $false
    }
}

# Export functions
Export-ModuleMember -Function Invoke-Cleanup, Dismount-TestWimImage
