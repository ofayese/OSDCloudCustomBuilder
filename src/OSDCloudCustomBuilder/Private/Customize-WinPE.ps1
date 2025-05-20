<#
.SYNOPSIS
    Customizes a WinPE image with additional components and configurations.
.DESCRIPTION
    This function customizes a Windows Preinstallation Environment (WinPE) image
    by adding drivers, packages, files, and registry settings. It provides a comprehensive
    customization solution for creating specialized WinPE environments.
.PARAMETER MountPath
    The path where the WinPE image is mounted.
.PARAMETER CustomizationPath
    The path containing customization files (drivers, scripts, etc.).
.PARAMETER AddPackages
    Array of WinPE optional package names to add.
.PARAMETER AddDrivers
    Path to driver folder to add to WinPE.
.PARAMETER RegistrySettings
    Hashtable of registry settings to apply.
.PARAMETER Wallpaper
    Path to a custom wallpaper image.
.PARAMETER StartupScript
    Path to a custom startup script.
.EXAMPLE
    Customize-WinPE -MountPath "C:\Mount\WinPE" -CustomizationPath "C:\OSDCloud\Custom"
.EXAMPLE
    Customize-WinPE -MountPath "C:\Mount\WinPE" -AddPackages @("WinPE-PowerShell", "WinPE-WMI")
.NOTES
    Requires Windows ADK and DISM module.
#>
function Customize-WinPE {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$MountPath,
        
        [Parameter()]
        [string]$CustomizationPath,
        
        [Parameter()]
        [string[]]$AddPackages,
        
        [Parameter()]
        [string]$AddDrivers,
        
        [Parameter()]
        [hashtable]$RegistrySettings,
        
        [Parameter()]
        [string]$Wallpaper,
        
        [Parameter()]
        [string]$StartupScript
    )
    
    begin {
        Write-OSDCloudLog -Message "Starting WinPE customization: $MountPath" -Level Info -Component "Customize-WinPE"
        
        # Verify mount path exists
        if (-not (Test-Path -Path $MountPath -PathType Container)) {
            $errorMsg = "Mount path not found: $MountPath"
            Write-OSDCloudLog -Message $errorMsg -Level Error -Component "Customize-WinPE"
            throw $errorMsg
        }
        
        # Verify DISM module is available
        if (-not (Get-Module -Name DISM -ListAvailable)) {
            $errorMsg = "DISM module not found. Please install Windows ADK."
            Write-OSDCloudLog -Message $errorMsg -Level Error -Component "Customize-WinPE"
            throw $errorMsg
        }
        
        # Check ADK WinPE add-on path
        $adkWinPEPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
        if (-not (Test-Path -Path $adkWinPEPath)) {
            $warningMsg = "Windows ADK WinPE Add-on path not found: $adkWinPEPath"
            Write-OSDCloudLog -Message $warningMsg -Level Warning -Component "Customize-WinPE"
            Write-Warning $warningMsg
        }
    }
    
    process {
        try {
            # Step 1: Add optional packages if specified
            if ($AddPackages -and $AddPackages.Count -gt 0) {
                Write-OSDCloudLog -Message "Adding packages to WinPE: $($AddPackages -join ', ')" -Level Info -Component "Customize-WinPE"
                
                foreach ($package in $AddPackages) {
                    $packagePath = Join-Path -Path $adkWinPEPath -ChildPath "amd64\WinPE_OCs\$package.cab"
                    
                    if (-not (Test-Path -Path $packagePath)) {
                        Write-OSDCloudLog -Message "Package not found: $packagePath" -Level Warning -Component "Customize-WinPE"
                        continue
                    }
                    
                    if ($PSCmdlet.ShouldProcess($packagePath, "Add package to WinPE")) {
                        try {
                            Add-WindowsPackage -Path $MountPath -PackagePath $packagePath -ErrorAction Stop
                            Write-OSDCloudLog -Message "Added package: $package" -Level Info -Component "Customize-WinPE"
                        }
                        catch {
                            Write-OSDCloudLog -Message "Failed to add package $package: $_" -Level Error -Component "Customize-WinPE" -Exception $_.Exception
                        }
                    }
                }
            }
            
            # Step 2: Add drivers if specified
            if ($AddDrivers -and (Test-Path -Path $AddDrivers -PathType Container)) {
                Write-OSDCloudLog -Message "Adding drivers from: $AddDrivers" -Level Info -Component "Customize-WinPE"
                
                if ($PSCmdlet.ShouldProcess($AddDrivers, "Add drivers to WinPE")) {
                    try {
                        Add-WindowsDriver -Path $MountPath -Driver $AddDrivers -Recurse -ErrorAction Stop
                        Write-OSDCloudLog -Message "Drivers added successfully" -Level Info -Component "Customize-WinPE"
                    }
                    catch {
                        Write-OSDCloudLog -Message "Failed to add drivers: $_" -Level Error -Component "Customize-WinPE" -Exception $_.Exception
                    }
                }
            }
            
            # Step 3: Copy customization files if specified
            if ($CustomizationPath -and (Test-Path -Path $CustomizationPath -PathType Container)) {
                Write-OSDCloudLog -Message "Copying customization files from: $CustomizationPath" -Level Info -Component "Customize-WinPE"
                
                if ($PSCmdlet.ShouldProcess($CustomizationPath, "Copy customization files to WinPE")) {
                    try {
                        Copy-Item -Path "$CustomizationPath\*" -Destination $MountPath -Recurse -Force -ErrorAction Stop
                        Write-OSDCloudLog -Message "Customization files copied successfully" -Level Info -Component "Customize-WinPE"
                    }
                    catch {
                        Write-OSDCloudLog -Message "Failed to copy customization files: $_" -Level Error -Component "Customize-WinPE" -Exception $_.Exception
                    }
                }
            }
            
            # Step 4: Set wallpaper if specified
            if ($Wallpaper -and (Test-Path -Path $Wallpaper -PathType Leaf)) {
                Write-OSDCloudLog -Message "Setting custom wallpaper: $Wallpaper" -Level Info -Component "Customize-WinPE"
                
                if ($PSCmdlet.ShouldProcess($Wallpaper, "Set custom wallpaper")) {
                    try {
                        $wallpaperDest = Join-Path -Path $MountPath -ChildPath "Windows\System32\winpe.jpg"
                        Copy-Item -Path $Wallpaper -Destination $wallpaperDest -Force -ErrorAction Stop
                        Write-OSDCloudLog -Message "Wallpaper set successfully" -Level Info -Component "Customize-WinPE"
                    }
                    catch {
                        Write-OSDCloudLog -Message "Failed to set wallpaper: $_" -Level Error -Component "Customize-WinPE" -Exception $_.Exception
                    }
                }
            }
            
            # Step 5: Configure startup script if specified
            if ($StartupScript -and (Test-Path -Path $StartupScript -PathType Leaf)) {
                Write-OSDCloudLog -Message "Setting startup script: $StartupScript" -Level Info -Component "Customize-WinPE"
                
                if ($PSCmdlet.ShouldProcess($StartupScript, "Set startup script")) {
                    try {
                        $startnetPath = Join-Path -Path $MountPath -ChildPath "Windows\System32\startnet.cmd"
                        $startupScriptName = Split-Path -Path $StartupScript -Leaf
                        $startupScriptDest = Join-Path -Path $MountPath -ChildPath "Windows\System32\$startupScriptName"
                        
                        # Copy the script
                        Copy-Item -Path $StartupScript -Destination $startupScriptDest -Force -ErrorAction Stop
                        
                        # Modify startnet.cmd to call the script
                        $startnetContent = Get-Content -Path $startnetPath -Raw -ErrorAction SilentlyContinue
                        if (-not $startnetContent) {
                            $startnetContent = "wpeinit`r`n"
                        }
                        
                        if (-not $startnetContent.Contains($startupScriptName)) {
                            $startnetContent += "`r`ncall %SYSTEMROOT%\System32\$startupScriptName`r`n"
                            Set-Content -Path $startnetPath -Value $startnetContent -Force -ErrorAction Stop
                        }
                        
                        Write-OSDCloudLog -Message "Startup script configured successfully" -Level Info -Component "Customize-WinPE"
                    }
                    catch {
                        Write-OSDCloudLog -Message "Failed to configure startup script: $_" -Level Error -Component "Customize-WinPE" -Exception $_.Exception
                    }
                }
            }
            
            # Step 6: Apply registry settings if specified
            if ($RegistrySettings -and $RegistrySettings.Count -gt 0) {
                Write-OSDCloudLog -Message "Applying registry settings" -Level Info -Component "Customize-WinPE"
                
                if ($PSCmdlet.ShouldProcess("Registry settings", "Apply to WinPE")) {
                    try {
                        $hiveFile = Join-Path -Path $MountPath -ChildPath "Windows\System32\config\SOFTWARE"
                        $tempHiveMountPoint = "HKLM\WinPE_SOFTWARE"
                        
                        # Load the hive
                        reg load $tempHiveMountPoint $hiveFile | Out-Null
                        
                        # Apply settings
                        foreach ($keyPath in $RegistrySettings.Keys) {
                            $fullKeyPath = "$tempHiveMountPoint\$keyPath"
                            $valueData = $RegistrySettings[$keyPath]
                            
                            # Create key if it doesn't exist
                            if (-not (Test-Path -Path "Registry::$fullKeyPath")) {
                                New-Item -Path "Registry::$fullKeyPath" -Force | Out-Null
                            }
                            
                            # Apply value
                            if ($valueData -is [hashtable]) {
                                foreach ($valueName in $valueData.Keys) {
                                    $value = $valueData[$valueName]
                                    
                                    if ($value -is [int]) {
                                        New-ItemProperty -Path "Registry::$fullKeyPath" -Name $valueName -Value $value -PropertyType DWORD -Force | Out-Null
                                    }
                                    elseif ($value -is [string]) {
                                        New-ItemProperty -Path "Registry::$fullKeyPath" -Name $valueName -Value $value -PropertyType String -Force | Out-Null
                                    }
                                    elseif ($value -is [string[]]) {
                                        New-ItemProperty -Path "Registry::$fullKeyPath" -Name $valueName -Value $value -PropertyType MultiString -Force | Out-Null
                                    }
                                    elseif ($value -is [byte[]]) {
                                        New-ItemProperty -Path "Registry::$fullKeyPath" -Name $valueName -Value $value -PropertyType Binary -Force | Out-Null
                                    }
                                }
                            }
                        }
                        
                        Write-OSDCloudLog -Message "Registry settings applied successfully" -Level Info -Component "Customize-WinPE"
                    }
                    catch {
                        Write-OSDCloudLog -Message "Failed to apply registry settings: $_" -Level Error -Component "Customize-WinPE" -Exception $_.Exception
                    }
                    finally {
                        # Unload the hive
                        [gc]::Collect()
                        reg unload $tempHiveMountPoint | Out-Null
                    }
                }
            }
            
            Write-OSDCloudLog -Message "WinPE customization completed successfully" -Level Info -Component "Customize-WinPE"
            return $true
        }
        catch {
            Write-OSDCloudLog -Message "Error during WinPE customization: $_" -Level Error -Component "Customize-WinPE" -Exception $_.Exception
            throw $_
        }
    }
}