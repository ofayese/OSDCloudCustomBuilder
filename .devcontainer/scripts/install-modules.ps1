# Install required PowerShell modules
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Status {
    param (
        [string]$Message
    )
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" -ForegroundColor Cyan
}

try {
    Write-Status "Starting PowerShell module installation"

    # Set PSGallery as trusted
    Write-Status "Setting PSGallery as trusted repository"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    # Define modules to install
    $modules = @(
        # Core modules for OSDCloud
        @{Name = 'OSD'; MinimumVersion = '23.5.5'; Description = 'OSD Module for OSDCloud functionality' },
        
        # Testing and quality tools
        @{Name = 'Pester'; MinimumVersion = '5.3.0'; Description = 'Testing framework' },
        @{Name = 'PSScriptAnalyzer'; MinimumVersion = '1.20.0'; Description = 'Static code analysis' },
        @{Name = 'PSCodeHealth'; Description = 'Code quality metrics' },
        
        # Module development tools
        @{Name = 'InvokeBuild'; Description = 'Build automation' },
        @{Name = 'BuildHelpers'; Description = 'Build and CI/CD helpers' },
        @{Name = 'Plaster'; Description = 'Scaffolding for PowerShell projects' },
        @{Name = 'platyPS'; Description = 'Documentation generation' },
        @{Name = 'PSDeploy'; Description = 'Deployment automation' },
        @{Name = 'ModuleBuilder'; Description = 'Module building and packaging' }
    )

    # Install modules
    foreach ($module in $modules) {
        $moduleName = $module.Name
        $moduleDescription = $module.Description
        
        Write-Status "Installing $moduleName - $moduleDescription"
        
        $installParams = @{
            Name = $moduleName
            Force = $true
            SkipPublisherCheck = $true
            AllowClobber = $true
            Scope = 'AllUsers'
        }
        
        if ($module.ContainsKey('MinimumVersion')) {
            $installParams.MinimumVersion = $module.MinimumVersion
            Write-Status "Requiring minimum version: $($module.MinimumVersion)"
        }
        
        try {
            Install-Module @installParams
            $installedModule = Get-Module -Name $moduleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
            Write-Status "Successfully installed $moduleName version $($installedModule.Version)"
        }
        catch {
            Write-Host "Warning: Failed to install $moduleName. Error: $_" -ForegroundColor Yellow
            Write-Host "Continuing with other modules..." -ForegroundColor Yellow
        }
    }

    # Verify installations
    Write-Status "Verifying module installations"
    $installedModules = Get-Module -ListAvailable | Where-Object { $modules.Name -contains $_.Name } | 
                        Select-Object Name, Version | Sort-Object Name
    
    Write-Status "Installed modules:"
    $installedModules | ForEach-Object {
        Write-Host "- $($_.Name) v$($_.Version)" -ForegroundColor Green
    }

    # Check for missing modules
    $missingModules = $modules.Name | Where-Object { $installedModules.Name -notcontains $_ }
    if ($missingModules) {
        Write-Host "Warning: The following modules could not be installed:" -ForegroundColor Yellow
        $missingModules | ForEach-Object {
            Write-Host "- $_" -ForegroundColor Yellow
        }
    }

    Write-Status "PowerShell module installation completed"
}
catch {
    Write-Host "Error installing PowerShell modules: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    throw
}
