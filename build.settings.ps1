# build.settings.ps1
$ModuleName = "OSDCloudCustomBuilder"
$SourcePath = $PSScriptRoot  # Now pointing to the root where the module files are
$OutputPath = "$PSScriptRoot\output"

# Auto-Versioning Configuration
$ModuleManifest = Join-Path $PSScriptRoot 'OSDCloudCustomBuilder.psd1'

# Get the existing version
$Manifest = Test-ModuleManifest -Path $ModuleManifest
$OldVersion = [System.Version]$Manifest.Version

# Calculate new build version (patch-level bump)
$NewVersion = '{0}.{1}.{2}' -f $OldVersion.Major, $OldVersion.Minor, ($OldVersion.Build + 1)

# Update .psd1 with new version
(Get-Content $ModuleManifest) -replace 'ModuleVersion\s*=\s*"[^"]+"', "ModuleVersion = `"$NewVersion`"" | Set-Content $ModuleManifest

Write-Host "Version updated to: $NewVersion"
