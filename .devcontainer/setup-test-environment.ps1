# Setup script for OSDCloudCustomBuilder test environment
[CmdletBinding()]
param()

Write-Host "Setting up test environment for OSDCloudCustomBuilder..." -ForegroundColor Cyan

# Create necessary directories
$modulesDir = Join-Path -Path $PSScriptRoot -ChildPath "../Modules"
if (-not (Test-Path -Path $modulesDir)) {
    New-Item -Path $modulesDir -ItemType Directory -Force | Out-Null
    Write-Host "Created Modules directory" -ForegroundColor Green
}

# Install required PowerShell modules
Write-Host "Installing required PowerShell modules..." -ForegroundColor Cyan
$modules = @(
    @{ Name = "Pester"; MinimumVersion = "5.0.0" },
    @{ Name = "ThreadJob"; MinimumVersion = "2.0.0" },
    @{ Name = "PSScriptAnalyzer"; MinimumVersion = "1.20.0" }
)

foreach ($module in $modules) {
    try {
        $installedModule = Get-Module -Name $module.Name -ListAvailable | 
                          Where-Object { $_.Version -ge $module.MinimumVersion } | 
                          Select-Object -First 1
        
        if (-not $installedModule) {
            Write-Host "Installing $($module.Name) module..." -ForegroundColor Yellow
            Install-Module -Name $module.Name -MinimumVersion $module.MinimumVersion -Force -SkipPublisherCheck
            Write-Host "$($module.Name) module installed successfully" -ForegroundColor Green
        } else {
            Write-Host "$($module.Name) module is already installed (v$($installedModule.Version))" -ForegroundColor Green
        }
    } catch {
        Write-Host "Failed to install $($module.Name) module: $_" -ForegroundColor Red
    }
}

# Create test folder structure if it doesn't exist
$testFolders = @(
    "Tests",
    "Tests/Unit", 
    "Tests/Security", 
    "Tests/Performance", 
    "Tests/ErrorHandling", 
    "Tests/Logging"
)

foreach ($folder in $testFolders) {
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath "../$folder"
    if (-not (Test-Path -Path $folderPath)) {
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
        Write-Host "Created $folder directory" -ForegroundColor Green
    }
}

# Symlink the module to the PowerShell modules path for easy importing
$moduleSource = Join-Path -Path $PSScriptRoot -ChildPath ".."
$moduleName = "OSDCloudCustomBuilder"
$moduleDest = Join-Path -Path $modulesDir -ChildPath $moduleName

if (-not (Test-Path -Path $moduleDest)) {
    try {
        # Determine if we're on Windows or Linux/macOS for the appropriate symlink command
        if ($IsWindows) {
            # Windows - Create directory junction
            New-Item -ItemType Junction -Path $moduleDest -Target $moduleSource -ErrorAction Stop | Out-Null
        } else {
            # Linux/macOS - Create symbolic link
            New-Item -ItemType SymbolicLink -Path $moduleDest -Target $moduleSource -ErrorAction Stop | Out-Null
        }
        Write-Host "Created symlink for the module at $moduleDest" -ForegroundColor Green
        
        # Verify the symlink was created successfully
        if (Test-Path -Path $moduleDest) {
            Write-Host "Verified symlink exists at $moduleDest" -ForegroundColor Green
        } else {
            Write-Warning "Symlink creation appeared to succeed but the path does not exist: $moduleDest"
        }
    } catch {
        Write-Warning "Failed to create symlink: $_"
        Write-Host "Falling back to copy method..." -ForegroundColor Yellow
        
        # Fallback to copying the module files
        try {
            Copy-Item -Path $moduleSource -Destination $moduleDest -Recurse -Force -ErrorAction Stop
            Write-Host "Copied module files to $moduleDest" -ForegroundColor Green
        } catch {
            Write-Error "Failed to copy module files: $_"
        }
    }
}

# Download PowerShell 7 package for testing
$pwsh7Version = "7.5.1"
$pwsh7ZipPath = Join-Path -Path $PSScriptRoot -ChildPath "../OSDCloud/PowerShell-$pwsh7Version-win-x64.zip"

if (-not (Test-Path -Path $pwsh7ZipPath)) {
    # Create the OSDCloud directory if it doesn't exist
    $osdCloudDir = Split-Path -Parent $pwsh7ZipPath
    if (-not (Test-Path -Path $osdCloudDir)) {
        try {
            New-Item -Path $osdCloudDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Host "Created OSDCloud directory" -ForegroundColor Green
        } catch {
            Write-Error "Failed to create OSDCloud directory: $_"
            # Try to create in a different location if the original fails
            $osdCloudDir = Join-Path -Path $env:TEMP -ChildPath "OSDCloud"
            $pwsh7ZipPath = Join-Path -Path $osdCloudDir -ChildPath "PowerShell-$pwsh7Version-win-x64.zip"
            
            try {
                if (-not (Test-Path -Path $osdCloudDir)) {
                    New-Item -Path $osdCloudDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }
                Write-Host "Created alternative OSDCloud directory at $osdCloudDir" -ForegroundColor Yellow
            } catch {
                Write-Error "Failed to create alternative OSDCloud directory: $_"
                return
            }
        }
    }
    
    # Download PowerShell 7 package
    try {
        $downloadUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$pwsh7Version/PowerShell-$pwsh7Version-win-x64.zip"
        Write-Host "Downloading PowerShell $pwsh7Version package..." -ForegroundColor Yellow
        
        # Set TLS 1.2 for secure downloads
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Download with retry logic
        $maxRetries = 3
        $retryCount = 0
        $downloadSuccess = $false
        
        while (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
            try {
                Invoke-WebRequest -Uri $downloadUrl -OutFile $pwsh7ZipPath -TimeoutSec 60 -ErrorAction Stop
                
                # Verify the file was downloaded
                if (Test-Path -Path $pwsh7ZipPath) {
                    $fileSize = (Get-Item -Path $pwsh7ZipPath).Length
                    if ($fileSize -gt 0) {
                        Write-Host "PowerShell $pwsh7Version package downloaded successfully ($([math]::Round($fileSize/1MB, 2)) MB)" -ForegroundColor Green
                        $downloadSuccess = $true
                    } else {
                        Write-Warning "Downloaded file is empty. Retrying..."
                        Remove-Item -Path $pwsh7ZipPath -Force
                        $retryCount++
                    }
                } else {
                    Write-Warning "Download appeared to succeed but file not found. Retrying..."
                    $retryCount++
                }
            } catch {
                Write-Warning "Download attempt $($retryCount + 1) failed: $_"
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    $delay = [math]::Pow(2, $retryCount) # Exponential backoff
                    Write-Host "Waiting $delay seconds before retrying..." -ForegroundColor Yellow
                    Start-Sleep -Seconds $delay
                }
            }
        }
        
        if (-not $downloadSuccess) {
            Write-Error "Failed to download PowerShell $pwsh7Version package after $maxRetries attempts."
        }
    } catch {
        Write-Error "Failed to download PowerShell $pwsh7Version package: $_"
    }
}

Write-Host "Test environment setup complete!" -ForegroundColor Green
Write-Host "To run tests, use: ./Run-Tests.ps1" -ForegroundColor Cyan
