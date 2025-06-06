# build.settings.ps1
$ModuleName = "OSDCloudCustomBuilder"
$SourcePath = $PSScriptRoot  # Uncommented as it's needed
$OutputPath = "$PSScriptRoot\output"

# Ensure output directory exists
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Auto-Versioning Configuration
$ModuleManifest = Join-Path $SourcePath "$ModuleName.psd1"

$Manifest = Test-ModuleManifest -Path $ModuleManifest
$OldVersion = [System.Version]$Manifest.Version
# Calculate new build version (patch-level bump)
$NewVersion = '{0}.{1}.{2}' -f $OldVersion.Major, $OldVersion.Minor, ($OldVersion.Build + 1)
# Update .psd1 with new version
(Get-Content $ModuleManifest) -replace 'ModuleVersion\s*=\s*"[^"]+"', "ModuleVersion = `"$NewVersion`"" | Set-Content $ModuleManifest
Write-Host "Version updated to: $NewVersion"
