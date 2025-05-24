function Test-OSDCloudCustomRequirements {
    [CmdletBinding()]
    param()

    begin {
        # Initialize results hashtable
        $results = @{
            IsValid = $true
            Warnings = @()
            MissingRequirements = @()
            RecommendedUpgrades = @()
        }

        # Log start of requirements check
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Starting requirements validation" -Level Info -Component "Test-OSDCloudCustomRequirements"
        }
    }

    process {
        try {
            # Check PowerShell version
            $minPSVersion = [Version]'5.1'
            $currentPSVersion = $PSVersionTable.PSVersion
            if ($currentPSVersion -lt $minPSVersion) {
                $results.IsValid = $false
                $results.MissingRequirements += "PowerShell $minPSVersion is required. Current version: $currentPSVersion"
            }
            elseif ($currentPSVersion.Major -lt 7) {
                $results.Warnings += "PowerShell 7+ is recommended for optimal performance. Current version: $currentPSVersion"
            }

            # Check required modules
            $requiredModules = @(
                @{Name = "OSD"; MinVersion = "23.5.2"; Required = $true},
                @{Name = "ThreadJob"; MinVersion = "2.0.0"; Required = $false}
            )

            foreach ($module in $requiredModules) {
                $installedModule = Get-Module -Name $module.Name -ListAvailable |
                                 Where-Object Version -ge $module.MinVersion |
                                 Sort-Object Version -Descending |
                                 Select-Object -First 1

                if (-not $installedModule) {
                    if ($module.Required) {
                        $results.IsValid = $false
                        $results.MissingRequirements += "$($module.Name) module version $($module.MinVersion) or higher is required"
                    }
                    else {
                        $results.RecommendedUpgrades += "$($module.Name) module version $($module.MinVersion) or higher is recommended"
                    }
                }
            }

            # Check admin privileges
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            if (-not $isAdmin) {
                $results.Warnings += "Administrator privileges are required for some operations"
            }

            # Check disk space
            $minFreeDiskSpaceGB = 10
            $systemDrive = (Get-PSDrive -Name C).Free / 1GB
            if ($systemDrive -lt $minFreeDiskSpaceGB) {
                $results.Warnings += "Low disk space on system drive: $([math]::Round($systemDrive,2))GB free. Minimum recommended: ${minFreeDiskSpaceGB}GB"
            }

            # Check Windows ADK installation
            $adkPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit"
            $adkWinPEPath = "$adkPath\Windows Preinstallation Environment"
            if (-not (Test-Path $adkPath)) {
                $results.IsValid = $false
                $results.MissingRequirements += "Windows ADK is not installed"
            }
            elseif (-not (Test-Path $adkWinPEPath)) {
                $results.IsValid = $false
                $results.MissingRequirements += "Windows ADK WinPE add-on is not installed"
            }

            # Check workspace paths
            $config = Get-OSDCloudConfig -ErrorAction Stop
            $requiredPaths = @(
                @{Path = $config.TempWorkspacePath; Name = "Workspace"; Required = $true},
                @{Path = $config.ISOOutputPath; Name = "ISO Output"; Required = $true}
            )

            foreach ($pathInfo in $requiredPaths) {
                if (-not (Test-Path $pathInfo.Path)) {
                    try {
                        New-Item -Path $pathInfo.Path -ItemType Directory -Force -ErrorAction Stop | Out-Null
                    }
                    catch {
                        if ($pathInfo.Required) {
                            $results.IsValid = $false
                            $results.MissingRequirements += "Cannot create required $($pathInfo.Name) directory: $($pathInfo.Path)"
                        }
                        else {
                            $results.Warnings += "Cannot create optional $($pathInfo.Name) directory: $($pathInfo.Path)"
                        }
                    }
                }
            }

            # Log results
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                $status = if ($results.IsValid) { "Requirements validation passed" } else { "Requirements validation failed" }
                Invoke-OSDCloudLogger -Message $status -Level Info -Component "Test-OSDCloudCustomRequirements"

                foreach ($req in $results.MissingRequirements) {
                    Invoke-OSDCloudLogger -Message "Missing requirement: $req" -Level Error -Component "Test-OSDCloudCustomRequirements"
                }

                foreach ($warning in $results.Warnings) {
                    Invoke-OSDCloudLogger -Message "Warning: $warning" -Level Warning -Component "Test-OSDCloudCustomRequirements"
                }
            }
        }
        catch {
            $results.IsValid = $false
            $results.MissingRequirements += "Error during requirements check: $_"

            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message "Requirements check failed: $_" -Level Error -Component "Test-OSDCloudCustomRequirements" -Exception $_.Exception
            }
        }
    }

    end {
        # Final logging
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Completed requirements validation" -Level Info -Component "Test-OSDCloudCustomRequirements"
        }

        return [PSCustomObject]$results
    }
}

Export-ModuleMember -Function Test-OSDCloudCustomRequirements
