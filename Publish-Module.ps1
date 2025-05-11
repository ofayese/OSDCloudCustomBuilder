# File: Publish-Module.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,
    
    [Parameter()]
    [switch]$Major,
    
    [Parameter()]
    [switch]$Minor,
    
    [Parameter()]
    [switch]$Patch,
    
    [Parameter()]
    [switch]$PreRelease,
    
    [Parameter()]
    [switch]$NoPublish
)

# Import required modules
Import-Module ModuleBuilder -Force

# Function to update version numbers
function Update-Version {
    param (
        [string]$CurrentVersion,
        [switch]$Major,
        [switch]$Minor,
        [switch]$Patch,
        [switch]$PreRelease
    )
    
    $parts = $CurrentVersion -split '\.'
    
    if ($Major) {
        [int]$parts[0] = [int]$parts[0] + 1
        $parts[1] = 0
        $parts[2] = 0
    }
    elseif ($Minor) {
        [int]$parts[1] = [int]$parts[1] + 1
        $parts[2] = 0
    }
    elseif ($Patch) {
        [int]$parts[2] = [int]$parts[2] + 1
    }
    
    $newVersion = $parts -join '.'
    if ($PreRelease) {
        $newVersion += "-preview"
    }
    
    return $newVersion
}

# Get current version from module manifest
$manifestPath = "./OSDCloudCustomBuilder.psd1"
$currentVersion = (Import-PowerShellDataFile -Path $manifestPath).ModuleVersion

# Calculate new version if not specified
if (-not $Version) {
    $Version = Update-Version -CurrentVersion $currentVersion -Major:$Major -Minor:$Minor -Patch:$Patch -PreRelease:$PreRelease
}

Write-Host "Updating from version $currentVersion to $Version" -ForegroundColor Yellow

# Update the module manifest
$manifestContent = Get-Content -Path $manifestPath -Raw
$manifestContent = $manifestContent -replace "ModuleVersion = '.*'", "ModuleVersion = '$Version'"
$manifestContent | Set-Content -Path $manifestPath -Force

# Build the module
Write-Host "Building module..." -ForegroundColor Cyan
./build.ps1 -Clean -Test

if (-not $NoPublish) {
    # Publish to PowerShell Gallery
    Write-Host "Publishing to PowerShell Gallery..." -ForegroundColor Cyan
    $buildOutput = Get-ChildItem -Path "./output" -Directory | Sort-Object -Property Name -Descending | Select-Object -First 1
    
    if ($buildOutput) {
        try {
            Publish-Module -Path $buildOutput.FullName -NuGetApiKey $env:PSGALLERY_API_KEY -ErrorAction Stop
            Write-Host "Module published successfully!" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to publish module: $_"
            exit 1
        }
    }
    else {
        Write-Error "No build output found!"
        exit 1
    }
}

Write-Host "Done!" -ForegroundColor Green
