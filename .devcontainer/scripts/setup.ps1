# Main setup script that calls other scripts
Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host "Starting container setup..." -ForegroundColor Cyan

try {
    # Install Windows ADK and WinPE addon
    Write-Host "Installing Windows ADK and WinPE addon..." -ForegroundColor Yellow
    & "$PSScriptRoot\install-adk.ps1"
    
    # Install PowerShell modules
    Write-Host "Installing PowerShell modules..." -ForegroundColor Yellow
    & "$PSScriptRoot\install-modules.ps1"
    
    # Configure environment
    Write-Host "Configuring environment..." -ForegroundColor Yellow
    & "$PSScriptRoot\configure-environment.ps1"
    
    Write-Host "Container setup completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error during container setup: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
