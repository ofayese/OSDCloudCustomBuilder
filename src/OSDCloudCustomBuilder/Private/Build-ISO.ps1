<#
.SYNOPSIS
    Creates an ISO file from the prepared WinPE workspace.
.DESCRIPTION
    This function builds an ISO file from the prepared WinPE workspace using the
    Windows Assessment and Deployment Kit (ADK) tools. It creates a bootable ISO
    with the custom WinPE environment.
.PARAMETER WorkspacePath
    The path to the prepared WinPE workspace.
.PARAMETER OutputPath
    The path where the ISO file will be created.
.PARAMETER ISOLabel
    The volume label for the ISO file. Default is "OSDCloud".
.EXAMPLE
    Build-ISO -WorkspacePath "C:\OSDCloud\Workspace" -OutputPath "C:\OSDCloud\Output\OSDCloud.iso"
.NOTES
    Requires Windows ADK with Deployment Tools installed.
#>
function Build-ISO {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$WorkspacePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter()]
        [string]$ISOLabel = "OSDCloud"
    )

    begin {
        Write-OSDCloudLog -Message "Starting ISO build process" -Level Info -Component "Build-ISO"
        
        # Verify ADK tools are available
        $oscdimgPath = "$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        if (-not (Test-Path $oscdimgPath)) {
            $errorMsg = "Windows ADK Deployment Tools not found. Please install Windows ADK with Deployment Tools."
            Write-OSDCloudLog -Message $errorMsg -Level Error -Component "Build-ISO"
            throw $errorMsg
        }
    }

    process {
        try {
            # Ensure output directory exists
            $outputDir = Split-Path -Path $OutputPath -Parent
            if (-not (Test-Path $outputDir)) {
                if ($PSCmdlet.ShouldProcess($outputDir, "Create directory")) {
                    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
                    Write-OSDCloudLog -Message "Created output directory: $outputDir" -Level Info -Component "Build-ISO"
                }
            }

            # Verify workspace exists
            if (-not (Test-Path $WorkspacePath)) {
                $errorMsg = "Workspace path not found: $WorkspacePath"
                Write-OSDCloudLog -Message $errorMsg -Level Error -Component "Build-ISO"
                throw $errorMsg
            }

            # Build the bootable ISO
            $etfsboot = "$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\etfsboot.com"
            $efisys = "$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys.bin"
            
            $oscdimgArgs = @(
                "-bootdata:2#p0,e,b`"$etfsboot`"#pEF,e,b`"$efisys`""
                "-u1" # UDF ISO format
                "-udfver102"
                "-l`"$ISOLabel`""
                $WorkspacePath
                $OutputPath
            )

            if ($PSCmdlet.ShouldProcess("$OutputPath", "Create ISO file")) {
                Write-OSDCloudLog -Message "Running oscdimg to create ISO file" -Level Info -Component "Build-ISO"
                Write-Verbose "Command: $oscdimgPath $($oscdimgArgs -join ' ')"
                
                $process = Start-Process -FilePath $oscdimgPath -ArgumentList $oscdimgArgs -NoNewWindow -Wait -PassThru
                
                if ($process.ExitCode -ne 0) {
                    $errorMsg = "ISO creation failed with exit code: $($process.ExitCode)"
                    Write-OSDCloudLog -Message $errorMsg -Level Error -Component "Build-ISO"
                    throw $errorMsg
                }
                
                if (Test-Path $OutputPath) {
                    $isoSize = (Get-Item $OutputPath).Length
                    Write-OSDCloudLog -Message "ISO created successfully at $OutputPath (Size: $([math]::Round($isoSize/1MB, 2)) MB)" -Level Info -Component "Build-ISO"
                    return $true
                }
                else {
                    $errorMsg = "ISO file not found at $OutputPath after creation attempt"
                    Write-OSDCloudLog -Message $errorMsg -Level Error -Component "Build-ISO"
                    throw $errorMsg
                }
            }
        }
        catch {
            Write-OSDCloudLog -Message "Error building ISO: $_" -Level Error -Component "Build-ISO" -Exception $_.Exception
            throw $_
        }
    }
}