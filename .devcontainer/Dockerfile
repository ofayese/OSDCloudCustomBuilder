# Use Windows Server Core LTSC 2022 as the base image
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Enable PowerShell in the container build steps
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Define ARG variables for version numbers
ARG POWERSHELL_VERSION
ARG PESTER_VERSION
ARG PSSCRIPTANALYZER_VERSION
ARG THREADJOB_VERSION
ARG OSD_VERSION
ARG OSDCLOUD_VERSION
ARG MODULEBUILDER_VERSION
ARG POWERSHELLPROTOOLS_VERSION

# Create required directories
RUN New-Item -Path C:\Temp -Type Directory -Force; \
    New-Item -Path C:\workspace -Type Directory -Force; \
    New-Item -Path C:\Users\ContainerAdministrator\Documents\PowerShell\Modules -Type Directory -Force

# Install PowerShell 7.5.1 (latest PowerShell Core)
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/PowerShell-${POWERSHELL_VERSION}-win-x64.msi -OutFile C:\Temp\PowerShell.msi; \
    Start-Process -FilePath msiexec.exe -ArgumentList '/i', 'C:\Temp\PowerShell.msi', '/quiet', '/norestart' -Wait; \
    Remove-Item -Path C:\Temp\PowerShell.msi -Force

# Switch to using PowerShell 7 (pwsh) for subsequent commands
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install necessary PowerShell modules (testing, analysis, OSD/OSDCloud, etc.)
RUN Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module -Name Pester -RequiredVersion ${PESTER_VERSION} -Force -SkipPublisherCheck; \
    Install-Module -Name PSScriptAnalyzer -RequiredVersion ${PSSCRIPTANALYZER_VERSION} -Force; \
    Install-Module -Name ThreadJob -RequiredVersion ${THREADJOB_VERSION} -Force; \
    Install-Module -Name OSDCloud -RequiredVersion ${OSDCLOUD_VERSION} -Force; \
    Install-Module -Name OSD -RequiredVersion ${OSD_VERSION} -Force; \
    Install-Module -Name PowerShellProTools -RequiredVersion ${POWERSHELLPROTOOLS_VERSION} -Force -SkipPublisherCheck; \
    Install-Module -Name ModuleBuilder -RequiredVersion ${MODULEBUILDER_VERSION} -Force

# Install Git (MinGit for Windows) for version control
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.40.0.windows.1/MinGit-2.40.0-64-bit.zip -OutFile C:\Temp\mingit.zip; \
    Expand-Archive -Path C:\Temp\mingit.zip -DestinationPath C:\Git -Force; \
    Remove-Item -Path C:\Temp\mingit.zip -Force; \
    $env:Path += ';C:\Git\cmd'; [Environment]::SetEnvironmentVariable('Path', $env:Path, [System.EnvironmentVariableTarget]::Machine)

# Install .NET SDKs (7.0 and 8.0)
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/6f7abf5c-3f6d-43cc-8f3c-700c27d4976b/b7a3b806505c95c7095ca1e8c057e987/dotnet-sdk-7.0.410-win-x64.exe -OutFile C:\Temp\dotnet7.exe; \
    Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/bd44cdb8-dcac-4f1f-8246-1ee392c68dac/ba818a6e513c305d4438c7da45c2b085/dotnet-sdk-8.0.406-win-x64.exe -OutFile C:\Temp\dotnet8.exe; \
    Start-Process -FilePath C:\Temp\dotnet7.exe -ArgumentList '/install', '/quiet', '/norestart' -Wait; \
    Start-Process -FilePath C:\Temp\dotnet8.exe -ArgumentList '/install', '/quiet', '/norestart' -Wait; \
    Remove-Item -Path C:\Temp\dotnet7.exe -Force; \
    Remove-Item -Path C:\Temp\dotnet8.exe -Force; \
    $env:Path += ';C:\Program Files\dotnet'; [Environment]::SetEnvironmentVariable('Path', $env:Path, [System.EnvironmentVariableTarget]::Machine)

# Install NuGet CLI for module packaging
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -Uri https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -OutFile C:\Git\cmd\nuget.exe

# Install Windows ADK (Deployment Tools, ICD, USMT) and Windows PE add-on
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    New-Item -Path C:\ADK -ItemType Directory -Force; \
    Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?linkid=2243390 -OutFile C:\ADK\adksetup.exe; \
    Start-Process -FilePath C:\ADK\adksetup.exe -ArgumentList '/quiet', '/installpath', 'C:\ADK', '/features', 'OptionId.DeploymentTools', 'OptionId.UserStateMigrationTool', 'OptionId.ImagingAndConfigurationDesigner' -Wait; \
    Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?linkid=2243391 -OutFile C:\ADK\adkwinpesetup.exe; \
    Start-Process -FilePath C:\ADK\adkwinpesetup.exe -ArgumentList '/quiet', '/installpath', 'C:\ADK', '/features', '+' -Wait; \
    Remove-Item -Path C:\ADK\adksetup.exe -Force; \
    Remove-Item -Path C:\ADK\adkwinpesetup.exe -Force

# Update PATH to include ADK Deployment Tools (DISM, etc.)
RUN $env:Path += ';C:\ADK\Assessment and Deployment Kit\Deployment Tools\amd64\DISM'; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path, [System.EnvironmentVariableTarget]::Machine)

# Copy initialization and test scripts into the container
COPY .devcontainer/container-init.ps1 C:\container-init.ps1
COPY .devcontainer/test-environment.ps1 C:\test-environment.ps1

# Set environment variables to disable PowerShell telemetry and fix globalization if needed
ENV POWERSHELL_TELEMETRY_OPTOUT=1
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
ENV TEMP=C:/Temp
ENV TMP=C:/Temp

# Set the default working directory and startup shell
WORKDIR C:/workspace
CMD ["pwsh"]
