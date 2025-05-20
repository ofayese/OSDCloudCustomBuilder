<#
.SYNOPSIS
    Performs cleanup operations on the OSDCloud workspace.
.DESCRIPTION
    This function cleans up temporary files and directories created during the OSDCloud
    customization process. It helps reclaim disk space and remove sensitive information.
.PARAMETER WorkspacePath
    The path to the OSDCloud workspace to clean up.
.PARAMETER RemoveAll
    If specified, removes all files including the workspace directory itself.
.PARAMETER PreserveLogFiles
    If specified, preserves log files during cleanup.
.EXAMPLE
    Cleanup-Workspace -WorkspacePath "C:\OSDCloud\Workspace"
.EXAMPLE
    Cleanup-Workspace -WorkspacePath "C:\OSDCloud\Workspace" -RemoveAll -Force
.NOTES
    Use the -WhatIf parameter to see what would be removed without actually removing files.
#>
function Clear-Workspace {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$WorkspacePath,

        [Parameter()]
        [switch]$RemoveAll,

        [Parameter()]
        [switch]$PreserveLogFiles,

        [Parameter()]
        [switch]$Force
    )

    begin {
        Write-OSDCloudLog -Message "Starting workspace cleanup: $WorkspacePath" -Level Info -Component "Clear-Workspace"

        # Check if workspace exists
        if (-not (Test-Path -Path $WorkspacePath -PathType Container)) {
            Write-OSDCloudLog -Message "Workspace path not found: $WorkspacePath" -Level Warning -Component "Clear-Workspace"
            return
        }

        # Define directories to clean up
        $tempDirs = @(
            "Mount",
            "Temp",
            "Cache",
            "Downloads"
        )

        # Define file patterns to clean up
        $tempFilePatterns = @(
            "*.tmp",
            "*.bak",
            "*.dism",
            "*.log"
        )

        # If preserving logs, remove log pattern
        if ($PreserveLogFiles) {
            $tempFilePatterns = $tempFilePatterns | Where-Object { $_ -ne "*.log" }
        }
    }

    process {
        try {
            # Remove temporary directories
            foreach ($dir in $tempDirs) {
                $dirPath = Join-Path -Path $WorkspacePath -ChildPath $dir
                if (Test-Path -Path $dirPath -PathType Container) {
                    if ($Force -or $PSCmdlet.ShouldProcess($dirPath, "Remove directory")) {
                        Write-OSDCloudLog -Message "Removing directory: $dirPath" -Level Info -Component "Clear-Workspace"
                        Remove-Item -Path $dirPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }

            # Remove temporary files
            foreach ($pattern in $tempFilePatterns) {
                $files = Get-ChildItem -Path $WorkspacePath -Filter $pattern -File -Recurse -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    if ($Force -or $PSCmdlet.ShouldProcess($file.FullName, "Remove file")) {
                        Write-OSDCloudLog -Message "Removing file: $($file.FullName)" -Level Info -Component "Clear-Workspace"
                        Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                    }
                }
            }

            # Remove the entire workspace if requested
            if ($RemoveAll) {
                if ($Force -or $PSCmdlet.ShouldProcess($WorkspacePath, "Remove entire workspace")) {
                    Write-OSDCloudLog -Message "Removing entire workspace: $WorkspacePath" -Level Info -Component "Clear-Workspace"
                    Remove-Item -Path $WorkspacePath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }

            Write-OSDCloudLog -Message "Workspace cleanup completed" -Level Info -Component "Clear-Workspace"
        }
        catch {
            Write-OSDCloudLog -Message "Error during workspace cleanup: $_" -Level Error -Component "Clear-Workspace" -Exception $_.Exception
            throw $_
        }
    }
}
