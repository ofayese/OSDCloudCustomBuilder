# Base image: Windows Server 2022
FROM mcr.microsoft.com/windows:ltsc2022

# Set shell to PowerShell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install Chocolatey
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install core tools
RUN choco install -y git 7zip vscode powershell-core dotnet-sdk

# Copy setup scripts
COPY scripts/ C:/setup/

# Run setup scripts
RUN C:/setup/setup.ps1

# Set PowerShell 7 as default shell
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Set working directory
WORKDIR C:/workspace

# Set environment variables
ENV PSModulePath="C:\Program Files\PowerShell\Modules;C:\Program Files\PowerShell\7\Modules;C:\Users\ContainerAdministrator\Documents\PowerShell\Modules;C:\Program Files\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules;C:\workspace"

# Expose ports if needed
# EXPOSE 80 443

# Set default command
CMD ["pwsh"]
