# Sets up the test environment for OSDCloudCustomBuilder tests

function Initialize-TestEnvironment {
    param (
        [Parameter()]
        [switch]$SkipModuleImport,

        [Parameter()]
        [switch]$CreateTempDirectories,

        [Parameter()]
        [string]$TestDataPath = "$PSScriptRoot\..\TestData"
}

    # Set strict mode for tests
    Set-StrictMode -Version Latest

    # Import module if not skipped
    if (-not $SkipModuleImport) {
        # Remove module if already loaded to ensure clean state
        if (Get-Module -Name OSDCloudCustomBuilder) {
            Remove-Module -Name OSDCloudCustomBuilder -Force -ErrorAction SilentlyContinue
        }

        # Import module from source path
        $modulePath = "$PSScriptRoot\..\..\src\OSDCloudCustomBuilder"
        Import-Module -Name $modulePath -Force -ErrorAction Stop
    }

    # Create test data directory if it doesn't exist
    if (-not (Test-Path -Path $TestDataPath)) {
        New-Item -Path $TestDataPath -ItemType Directory -Force | Out-Null
    }

    # Create temporary directories if requested
    if ($CreateTempDirectories) {
        $tempBasePath = Join-Path -Path $TestDataPath -ChildPath "Temp"
        $tempPaths = @{
            Base = $tempBasePath
            Mount = Join-Path -Path $tempBasePath -ChildPath "Mount"
            Workspace = Join-Path -Path $tempBasePath -ChildPath "Workspace"
            Output = Join-Path -Path $tempBasePath -ChildPath "Output"
            Logs = Join-Path -Path $tempBasePath -ChildPath "Logs"
        }

        # Create each temp directory
        foreach ($path in $tempPaths.Values) {
            if (-not (Test-Path -Path $path)) {
                New-Item -Path $path -ItemType Directory -Force | Out-Null
            }
        }

        # Return the paths for use in tests
        return $tempPaths
    }

    return $true
}

function Reset-TestEnvironment {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$TestDataPath = "$PSScriptRoot\..\TestData"
    )

    # Clean up temp directories if they exist
    $tempBasePath = Join-Path -Path $TestDataPath -ChildPath "Temp"
    if (Test-Path -Path $tempBasePath) {
        Remove-Item -Path $tempBasePath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Export functions
Export-ModuleMember -Function Initialize-TestEnvironment, Reset-TestEnvironment
