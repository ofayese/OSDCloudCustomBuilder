[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Installing PowerShell development modules..."

$modules = @(
    @{ Name = "Pester"; Description = "A testing framework for PowerShell, essential for writing and running unit tests for your scripts and modules." },
    @{ Name = "Plaster"; Description = "A scaffolding module that helps you create consistent project structures for your PowerShell modules." },
    @{ Name = "PSReadLine"; Description = "Enhances the command-line editing experience in PowerShell, providing syntax highlighting and better history navigation." },
    @{ Name = "PSScriptAnalyzer"; Description = "A static code analysis tool that checks your PowerShell code for best practices and style guidelines." },
    @{ Name = "PowerShellGet"; Description = "Allows you to discover, install, update, and publish PowerShell packages." },
    @{ Name = "PSDepend"; Description = "A simple dependency handler for PowerShell, useful for managing module dependencies." },
    @{ Name = "InvokeBuild"; Description = "A build and task automation module for PowerShell, similar to make or rake." },
    @{ Name = "ModuleBuilder"; Description = "Helps in building and packaging PowerShell modules, making it easier to distribute your work." },
    @{ Name = "PSModuleDevelopment"; Description = "Provides tools to assist in the development of PowerShell modules, including templates and testing support." },
    @{ Name = "OSD"; Description = "OS deployment automation and customization." },
    @{ Name = "PowerShellProTools"; Description = "Adds productivity enhancements for PowerShell developers." }
)

foreach ($mod in $modules) {
    Write-Host "`n--- Installing $($mod.Name) ---`n$($mod.Description)"
    try {
        Install-Module -Name $($mod.Name) -Force -Scope CurrentUser -ErrorAction Stop
    } catch {
        Write-Warning "Failed to install $($mod.Name): $_"
    }
}

Write-Host "`nAll module installation attempts complete."
Get-InstalledModule | Select-Object Name, Version
