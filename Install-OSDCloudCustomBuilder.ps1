# Install-OSDCloudCustomBuilder.ps1
param (
    [string]$DestinationPath = "$HOME\Documents\PowerShell\Modules\OSDCloudCustomBuilder"
)

Write-Host "Installing OSDCloudCustomBuilder to: $DestinationPath"

if (-not (Test-Path -Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
}

Copy-Item -Path "$PSScriptRoot\*" -Destination $DestinationPath -Recurse -Force

Write-Host "Installation complete."
