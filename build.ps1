# File: build.ps1
[CmdletBinding()]
param(
    [switch]$UpdateVersion,
    [switch]$Clean,
    [switch]$Package,
    [switch]$Test
)

# Import required modules
Import-Module -Name ModuleBuilder -Force

if ($Clean) {
    # Clean output directory
    if (Test-Path -Path "./output") {
        Remove-Item -Path "./output" -Recurse -Force
    }
}

# Build the module
Build-Module -Path . -Verbose

if ($Test) {
    # Run tests
    ./Run-Tests.ps1
}

if ($Package) {
    # Create the module package
    $buildOutput = Get-ChildItem -Path "./output" -Directory | Sort-Object -Property Name -Descending | Select-Object -First 1
    if ($buildOutput) {
        $modulePath = $buildOutput.FullName
        $moduleName = Split-Path -Path $modulePath -Leaf
        $moduleVersion = (Import-PowerShellDataFile -Path (Join-Path -Path $modulePath -ChildPath "$moduleName.psd1")).ModuleVersion
        
        # Create package
        $packagePath = "./packages"
        if (-not (Test-Path -Path $packagePath)) {
            New-Item -Path $packagePath -ItemType Directory -Force | Out-Null
        }
        
        Compress-Archive -Path $modulePath -DestinationPath "$packagePath/$moduleName-$moduleVersion.zip" -Force
        Write-Host "Created package: $packagePath/$moduleName-$moduleVersion.zip" -ForegroundColor Green
    }
    else {
        Write-Error "No build output found in ./output directory"
    }
}
