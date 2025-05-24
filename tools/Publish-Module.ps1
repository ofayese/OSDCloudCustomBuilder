# tools/Publish-Module.ps1 - Local build and install script

$ModuleName = "OSDCloudCustomBuilder"
$ModuleRoot = "$PSScriptRoot\.."
$Destination = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$ModuleName"

Write-Host "🧪 Running Pester tests with code coverage..."
Invoke-Pester -Path "$ModuleRoot\tests" -CI -CodeCoverage "$ModuleRoot\$ModuleName"

Write-Host "🧹 Cleaning previous install at $Destination..."
if (Test-Path $Destination) {
    Remove-Item -Recurse -Force -Path $Destination
}

Write-Host "📦 Copying module to $Destination..."
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
Copy-Item -Path "$ModuleRoot\*.psd1", "$ModuleRoot\*.psm1" -Destination $Destination -Force
Copy-Item -Path "$ModuleRoot\Public", "$ModuleRoot\Private", "$ModuleRoot\Shared" -Destination $Destination -Recurse -Force

Write-Host "✅ Module installed locally: $Destination"
