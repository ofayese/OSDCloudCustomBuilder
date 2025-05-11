# This script runs when the container starts
Write-Host "Initializing OSDCloudCustomBuilder development environment..." -ForegroundColor Cyan

# Verify we're running in Windows
if (-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
    Write-Error "This container must run on Windows!"
    exit 1
}

# Ensure TLS 1.2 is enabled for secure connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Ensure PSGallery is trusted
if ((Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue).InstallationPolicy -ne 'Trusted') {
    try {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
        Write-Host "Set PSGallery to trusted" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to set PSGallery to trusted: $_"
    }
}

# Update PowerShell modules if needed
Write-Host "Checking for module updates..." -ForegroundColor Cyan
foreach ($module in @('Pester', 'PSScriptAnalyzer', 'ThreadJob', 'OSD', 'OSDCloud')) {
    try {
        $latest = Find-Module -Name $module -Repository PSGallery -ErrorAction Stop
        $current = Get-Module -Name $module -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

        if ($current -and $latest.Version -gt $current.Version) {
            Write-Host "Updating $module from $($current.Version) to $($latest.Version)..." -ForegroundColor Yellow
            Update-Module -Name $module -Force -ErrorAction Stop
        }
        else {
            Write-Host "Module $module is up to date (v$($current.Version))" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Failed to check/update module $module`: $_"
    }
}

# Run the test environment script
Write-Host "Running test environment verification..." -ForegroundColor Cyan
try {
    & "$PSScriptRoot/test-environment.ps1"
}
catch {
    Write-Error "Error running test environment script: $_"
}

Write-Host "Container initialization complete!" -ForegroundColor Green
