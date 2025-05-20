$ModulePath = Get-ChildItem -Path "$PSScriptRoot/out" -Filter *.psd1 | Select-Object -First 1
if (-not $ModulePath) {
    Write-Error "No built module found. Run build.ps1 first."
    exit 1
}
Publish-Module -Path $ModulePath.FullName -NuGetApiKey $env:PSGALLERY_API_KEY -Verbose
