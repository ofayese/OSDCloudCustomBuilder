# Use the official PowerShell 7.5.1 image on Windows Server Core
FROM mcr.microsoft.com/powershell:7.5.1-windowsservercore-ltsc2022

# Set shell to PowerShell 7
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install required PowerShell modules with minimum versions
RUN Install-Module -Name Pester -MinimumVersion 5.4.0 -Force -SkipPublisherCheck
RUN Install-Module -Name PSScriptAnalyzer -MinimumVersion 1.21.0 -Force -SkipPublisherCheck
RUN Install-Module -Name ThreadJob -MinimumVersion 2.0.3 -Force -SkipPublisherCheck
RUN Install-Module -Name OSD -MinimumVersion 23.5.26 -Force -SkipPublisherCheck
RUN Install-Module -Name OSDCloud -MinimumVersion 23.5.26 -Force -SkipPublisherCheck

# Ensure DISM and other Windows deployment tools are available
# These are typically included in Windows Server Core, but we'll verify
RUN if (-not (Get-Command -Name 'DISM.exe' -ErrorAction SilentlyContinue)) { \
    Write-Warning 'DISM not found. Some OSDCloudCustomBuilder features may not work properly.' \
    }

# Download PowerShell 7.5.1 package for testing
RUN New-Item -Path 'C:\OSDCloud' -ItemType Directory -Force
RUN Invoke-WebRequest -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/PowerShell-7.5.1-win-x64.zip' -OutFile 'C:\OSDCloud\PowerShell-7.5.1-win-x64.zip'

# Install Windows ADK and Windows PE add-on
# Create a temporary directory for the installers
RUN New-Item -Path 'C:\Temp' -ItemType Directory -Force

# Download Windows ADK installer
RUN Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2243390' -OutFile 'C:\Temp\adksetup.exe'

# Install Windows ADK (silent installation with required components)
RUN Start-Process -FilePath 'C:\Temp\adksetup.exe' -ArgumentList '/quiet', '/features', 'OptionId.DeploymentTools OptionId.UserStateMigrationTool OptionId.ImagingAndConfigurationDesigner' -Wait

# Download Windows PE add-on
RUN Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2243391' -OutFile 'C:\Temp\adkwinpesetup.exe'

# Install Windows PE add-on
RUN Start-Process -FilePath 'C:\Temp\adkwinpesetup.exe' -ArgumentList '/quiet' -Wait

# Clean up temporary files
RUN Remove-Item -Path 'C:\Temp' -Recurse -Force

# Set working directory
WORKDIR C:/workspace

# Set PowerShell 7 as the default entrypoint
ENTRYPOINT ["pwsh", "-NoLogo", "-ExecutionPolicy", "Bypass"]
