# Simple test to check our admin mocking
Import-Module (Join-Path $PSScriptRoot '..\OSDCloudCustomBuilder.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'TestHelpers\Admin-MockHelper.psm1') -Force

# Set up admin mocking
Set-TestAdminContext -IsAdmin $true -Verbose

# Test if admin mocking works
$IsAdmin = & (Get-Module OSDCloudCustomBuilder) { Test-IsAdmin }

if ($IsAdmin -eq $true) {
    Write-Host "SUCCESS: Test-IsAdmin returns TRUE as expected" -ForegroundColor Green
} else {
    Write-Host "FAIL: Test-IsAdmin returns FALSE, expected TRUE" -ForegroundColor Red
}

# Also check our script:Test-IsAdmin mock
if (Test-IsAdmin) {
    Write-Host "SUCCESS: Script Test-IsAdmin returns TRUE as expected" -ForegroundColor Green
} else {
    Write-Host "FAIL: Script Test-IsAdmin returns FALSE, expected TRUE" -ForegroundColor Red
}
