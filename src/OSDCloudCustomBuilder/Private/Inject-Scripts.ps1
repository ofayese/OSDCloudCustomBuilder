<#
.SYNOPSIS
    Injects custom scripts into a WinPE image.
.DESCRIPTION
    This function injects custom scripts into a mounted WinPE image, allowing
    for automated tasks during WinPE startup. It supports both PowerShell and
    batch scripts, with options for execution order and dependencies.
.PARAMETER MountPath
    The path where the WinPE image is mounted.
.PARAMETER ScriptsPath
    The path containing scripts to inject into WinPE.
.PARAMETER StartupScript
    The name of the script to run at WinPE startup.
.PARAMETER TargetDirectory
    The directory within WinPE where scripts will be placed.
.PARAMETER ExecutionOrder
    Array of script names in the order they should be executed.
.PARAMETER AddToStartnet
    If specified, adds the startup script to startnet.cmd.
.EXAMPLE
    Inject-Scripts -MountPath "C:\Mount\WinPE" -ScriptsPath "C:\OSDCloud\Scripts" -StartupScript "Start-OSDCloud.ps1"
.NOTES
    This function requires a mounted WinPE image.
#>
function Inject-Scripts {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$MountPath,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptsPath,
        
        [Parameter()]
        [string]$StartupScript,
        
        [Parameter()]
        [string]$TargetDirectory = "OSDCloud\Scripts",
        
        [Parameter()]
        [string[]]$ExecutionOrder,
        
        [Parameter()]
        [switch]$AddToStartnet
    )
    
    begin {
        Write-OSDCloudLog -Message "Starting script injection: $MountPath" -Level Info -Component "Inject-Scripts"
        
        # Verify mount path exists
        if (-not (Test-Path -Path $MountPath -PathType Container)) {
            $errorMsg = "Mount path not found: $MountPath"
            Write-OSDCloudLog -Message $errorMsg -Level Error -Component "Inject-Scripts"
            throw $errorMsg
        }
        
        # Verify scripts path exists
        if (-not (Test-Path -Path $ScriptsPath -PathType Container)) {
            $errorMsg = "Scripts path not found: $ScriptsPath"
            Write-OSDCloudLog -Message $errorMsg -Level Error -Component "Inject-Scripts"
            throw $errorMsg
        }
        
        # Create target directory path
        $fullTargetPath = Join-Path -Path $MountPath -ChildPath $TargetDirectory
    }
    
    process {
        try {
            # Step 1: Create target directory if it doesn't exist
            if (-not (Test-Path -Path $fullTargetPath -PathType Container)) {
                if ($PSCmdlet.ShouldProcess($fullTargetPath, "Create directory")) {
                    Write-OSDCloudLog -Message "Creating target directory: $fullTargetPath" -Level Info -Component "Inject-Scripts"
                    New-Item -Path $fullTargetPath -ItemType Directory -Force | Out-Null
                }
            }
            
            # Step 2: Copy scripts to target directory
            $scriptFiles = Get-ChildItem -Path $ScriptsPath -File -Recurse
            
            if ($scriptFiles.Count -eq 0) {
                Write-OSDCloudLog -Message "No script files found in: $ScriptsPath" -Level Warning -Component "Inject-Scripts"
                return
            }
            
            if ($PSCmdlet.ShouldProcess("$($scriptFiles.Count) script files", "Copy to WinPE")) {
                Write-OSDCloudLog -Message "Copying $($scriptFiles.Count) script files to WinPE" -Level Info -Component "Inject-Scripts"
                
                foreach ($scriptFile in $scriptFiles) {
                    $relativePath = $scriptFile.FullName.Substring($ScriptsPath.Length)
                    $destinationPath = Join-Path -Path $fullTargetPath -ChildPath $relativePath
                    $destinationDir = Split-Path -Path $destinationPath -Parent
                    
                    # Create directory structure if needed
                    if (-not (Test-Path -Path $destinationDir -PathType Container)) {
                        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                    }
                    
                    # Copy the file
                    Copy-Item -Path $scriptFile.FullName -Destination $destinationPath -Force
                    Write-OSDCloudLog -Message "Copied script: $($scriptFile.Name)" -Level Info -Component "Inject-Scripts"
                }
            }
            
            # Step 3: Create startup launcher if specified
            if ($StartupScript) {
                $startupScriptPath = Join-Path -Path $fullTargetPath -ChildPath $StartupScript
                
                if (-not (Test-Path -Path $startupScriptPath -PathType Leaf)) {
                    $warningMsg = "Startup script not found: $StartupScript"
                    Write-OSDCloudLog -Message $warningMsg -Level Warning -Component "Inject-Scripts"
                    Write-Warning $warningMsg
                }
                else {
                    # Create launcher based on script type
                    $scriptExtension = [System.IO.Path]::GetExtension($StartupScript).ToLower()
                    $launcherPath = Join-Path -Path $MountPath -ChildPath "Windows\System32\OSDCloudStartup.cmd"
                    
                    if ($PSCmdlet.ShouldProcess($launcherPath, "Create startup launcher")) {
                        Write-OSDCloudLog -Message "Creating startup launcher: $launcherPath" -Level Info -Component "Inject-Scripts"
                        
                        $launcherContent = "@echo off`r`n"
                        $launcherContent += "echo Starting OSDCloud scripts...`r`n"
                        
                        if ($scriptExtension -eq ".ps1") {
                            # For PowerShell scripts
                            $relativePath = $TargetDirectory.Replace("\", "/")
                            $launcherContent += "powershell -ExecutionPolicy Bypass -File X:\$relativePath\$StartupScript"
                            
                            if ($ExecutionOrder -and $ExecutionOrder.Count -gt 0) {
                                $launcherContent += " -ExecutionOrder " + ($ExecutionOrder -join ",")
                            }
                            
                            $launcherContent += "`r`n"
                        }
                        else {
                            # For batch scripts
                            $relativePath = $TargetDirectory
                            $launcherContent += "call X:\$relativePath\$StartupScript`r`n"
                        }
                        
                        # Write the launcher
                        Set-Content -Path $launcherPath -Value $launcherContent -Force
                        
                        # Add to startnet.cmd if requested
                        if ($AddToStartnet) {
                            $startnetPath = Join-Path -Path $MountPath -ChildPath "Windows\System32\startnet.cmd"
                            
                            if (Test-Path -Path $startnetPath -PathType Leaf) {
                                $startnetContent = Get-Content -Path $startnetPath -Raw
                                
                                if (-not $startnetContent.Contains("OSDCloudStartup.cmd")) {
                                    Write-OSDCloudLog -Message "Adding launcher to startnet.cmd" -Level Info -Component "Inject-Scripts"
                                    
                                    # Ensure startnet.cmd ends with a newline
                                    if (-not $startnetContent.EndsWith("`n")) {
                                        $startnetContent += "`r`n"
                                    }
                                    
                                    $startnetContent += "call %SYSTEMROOT%\System32\OSDCloudStartup.cmd`r`n"
                                    Set-Content -Path $startnetPath -Value $startnetContent -Force
                                }
                            }
                            else {
                                $warningMsg = "startnet.cmd not found: $startnetPath"
                                Write-OSDCloudLog -Message $warningMsg -Level Warning -Component "Inject-Scripts"
                                Write-Warning $warningMsg
                            }
                        }
                    }
                }
            }
            
            Write-OSDCloudLog -Message "Script injection completed successfully" -Level Info -Component "Inject-Scripts"
            return $true
        }
        catch {
            Write-OSDCloudLog -Message "Error during script injection: $_" -Level Error -Component "Inject-Scripts" -Exception $_.Exception
            throw $_
        }
    }
}