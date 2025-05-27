param(
    [string]$ModuleName = "OSDCloudCustomBuilder",
    [string]$Destination = "$PWD\OSDCloudCustomBuilder"
)

Write-Host "📁 Creating new module scaffold: $Destination"

# Create folder structure
$folders = @("Public", "Private", "Shared", "tests", ".github\workflows", ".vscode", ".devcontainer", "tools")
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force -Path (Join-Path $Destination $folder) | Out-Null
}

# Copy template files (assumes script is run from root of OSDCloudCustomBuilder)
$sourceRoot = "$PSScriptRoot\.."
$copyFiles = @(
    "*.psd1", "*.psm1", "build.ps1", "build.settings.ps1",
    "config.schema.psd1", "PSScriptAnalyzer.settings.psd1", "requirements.psd1", "README.md"
)

foreach ($file in $copyFiles) {
    Get-ChildItem -Path $sourceRoot -Filter $file | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $Destination
    }
}

# Copy CI, DevContainer, VSCode setup
Copy-Item "$sourceRoot\.vscode\*" -Destination "$Destination\.vscode" -Recurse
Copy-Item "$sourceRoot\.devcontainer\*" -Destination "$Destination\.devcontainer" -Recurse
Copy-Item "$sourceRoot\.github\workflows\*" -Destination "$Destination\.github\workflows" -Recurse
Copy-Item "$sourceRoot\tools\Publish-Module.ps1" -Destination "$Destination\tools\Publish-Module.ps1"

Write-Host "✅ Scaffold created. To begin:"
Write-Host "`n  cd $Destination"
Write-Host "  code ."
