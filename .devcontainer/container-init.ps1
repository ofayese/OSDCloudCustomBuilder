# This script runs when the container starts
Write-Host "Initializing OSDCloudCustomBuilder development environment..." -ForegroundColor Cyan

# Ensure PSGallery is trusted
if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Write-Host "Set PSGallery to trusted" -ForegroundColor Green
}

# Update PowerShell modules if needed
Write-Host "Checking for module updates..." -ForegroundColor Cyan
foreach ($module in @('Pester', 'PSScriptAnalyzer', 'ThreadJob', 'OSD', 'OSDCloud')) {
    $latest = Find-Module -Name $module -Repository PSGallery
    $current = Get-Module -Name $module -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

    if ($current -and $latest.Version -gt $current.Version) {
        Write-Host "Updating $module from $($current.Version) to $($latest.Version)..." -ForegroundColor Yellow
        Update-Module -Name $module -Force
    }
}

# Run the test environment script
& "$PSScriptRoot/test-environment.ps1"
