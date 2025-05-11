# Use Windows Server Core LTSC 2022 as the base image
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Set shell to PowerShell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Create necessary directories
RUN New-Item -Path C:\Temp -Type Directory -Force; \
    New-Item -Path C:\workspace -Type Directory -Force; \
    New-Item -Path C:\Users\ContainerAdministrator\Documents\PowerShell\Modules -Type Directory -Force

# Install PowerShell 7.5.1
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/PowerShell-7.5.1-win-x64.msi -OutFile C:\Temp\PowerShell.msi ; \
    Start-Process -FilePath msiexec.exe -ArgumentList '/i', 'C:\Temp\PowerShell.msi', '/quiet', '/norestart' -Wait ; \
    Remove-Item -Path C:\Temp\PowerShell.msi -Force

# Set shell to PowerShell 7
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install necessary PowerShell modules
RUN Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module -Name Pester -RequiredVersion 5.4.0 -Force -SkipPublisherCheck; \
    Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.21.0 -Force; \
    Install-Module -Name ThreadJob -RequiredVersion 2.0.3 -Force; \
    Install-Module -Name OSDCloud -RequiredVersion 23.5.26 -Force; \
    Install-Module -Name OSD -RequiredVersion 23.5.26 -Force

# Install Git
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.40.0.windows.1/MinGit-2.40.0-64-bit.zip -OutFile C:\Temp\mingit.zip; \
    Expand-Archive -Path C:\Temp\mingit.zip -DestinationPath C:\Git -Force; \
    Remove-Item -Path C:\Temp\mingit.zip -Force; \
    $env:Path += ';C:\Git\cmd'; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path, [System.EnvironmentVariableTarget]::Machine)

# Install Windows ADK (Assessment and Deployment Kit) and Windows PE add-on
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    New-Item -Path C:\ADK -ItemType Directory -Force; \
    Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?linkid=2243390 -OutFile C:\ADK\adksetup.exe; \
    Start-Process -FilePath C:\ADK\adksetup.exe -ArgumentList '/quiet', '/installpath', 'C:\ADK', '/features', 'OptionId.DeploymentTools', 'OptionId.UserStateMigrationTool', 'OptionId.ImagingAndConfigurationDesigner' -Wait; \
    Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?linkid=2243391 -OutFile C:\ADK\adkwinpesetup.exe; \
    Start-Process -FilePath C:\ADK\adkwinpesetup.exe -ArgumentList '/quiet', '/installpath', 'C:\ADK', '/features', '+' -Wait; \
    Remove-Item -Path C:\ADK\adksetup.exe -Force; \
    Remove-Item -Path C:\ADK\adkwinpesetup.exe -Force

# Update Path to include DISM
RUN $env:Path += ';C:\ADK\Assessment and Deployment Kit\Deployment Tools\amd64\DISM'; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path, [System.EnvironmentVariableTarget]::Machine)

# Copy initialization scripts
COPY .devcontainer/container-init.ps1 C:/container-init.ps1
COPY .devcontainer/test-environment.ps1 C:/test-environment.ps1

# Set environment variables
ENV POWERSHELL_TELEMETRY_OPTOUT=1
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
ENV TEMP=C:/Temp
ENV TMP=C:/Temp

# Default to PowerShell 7
WORKDIR C:/workspace
CMD ["pwsh"]
