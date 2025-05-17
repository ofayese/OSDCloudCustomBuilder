# Setup-GitGPG.ps1
# This script helps configure Git to use GPG signing properly
param (
    [switch]$EnableSigning = $false,
    [string]$GpgPath = "C:\Program Files\GnuPG\bin\gpg.exe"
)

# Check if GPG is installed
$gpgInstalled = Test-Path $GpgPath
if (-not $gpgInstalled) {
    Write-Host "GPG not found at $GpgPath" -ForegroundColor Yellow
    Write-Host "You have two options:" -ForegroundColor Cyan
    Write-Host "1. Install GPG from https://gnupg.org/download/" -ForegroundColor Cyan
    Write-Host "2. Continue with signing disabled" -ForegroundColor Cyan
    
    $choice = Read-Host "Do you want to continue with signing disabled? (Y/N)"
    if ($choice -eq "Y" -or $choice -eq "y") {
        Write-Host "Disabling Git commit signing..." -ForegroundColor Green
        git config --global commit.gpgsign false
        Write-Host "Git commit signing has been disabled." -ForegroundColor Green
        return
    } else {
        Write-Host "Please install GPG and run this script again." -ForegroundColor Yellow
        return
    }
}

# If we get here, GPG is installed
Write-Host "GPG found at $GpgPath" -ForegroundColor Green

# Configure Git to use the correct GPG program
git config --global gpg.program $GpgPath
Write-Host "Git configured to use GPG at $GpgPath" -ForegroundColor Green

if ($EnableSigning) {
    # List GPG keys
    Write-Host "Available GPG keys:" -ForegroundColor Cyan
    & $GpgPath --list-secret-keys --keyid-format LONG
    
    # Get key ID from user
    $keyId = Read-Host "Enter your GPG key ID (the 16-character hexadecimal ID after 'sec rsa4096/')"
    
    # Configure Git to use this key for signing
    git config --global user.signingkey $keyId
    git config --global commit.gpgsign true
    Write-Host "Git commit signing has been enabled with key $keyId" -ForegroundColor Green
} else {
    # Disable signing for now but keep the GPG path configuration
    git config --global commit.gpgsign false
    Write-Host "Git commit signing has been disabled." -ForegroundColor Green
    Write-Host "To enable signing later, run this script with -EnableSigning" -ForegroundColor Cyan
}

Write-Host "Git GPG configuration complete!" -ForegroundColor Green
