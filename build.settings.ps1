# File: build.settings.ps1
@{
    Path = Join-Path -Path $PSScriptRoot -ChildPath "OSDCloudCustomBuilder"
    OutputDirectory = Join-Path -Path $PSScriptRoot -ChildPath "output"
    SourceDirectories = @(
        'Public',
        'Private',
        'Shared'
    )
    CopyDirectories = @(
        'docs',
        'en-US'  # PowerShell help files
    )
    Encoding = 'UTF8'
    VersionedOutputDirectory = $true
    CompanyName = 'Modern Endpoint Management'
}
