# Multi-stage Dockerfile for OSDCloudCustomBuilder Development
FROM mcr.microsoft.com/devcontainers/base:dev-ubuntu-24.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
ENV DOTNET_NOLOGO=1
ENV POWERSHELL_TELEMETRY_OPTOUT=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    unzip \
    wget \
    jq \
    nano \
    vim \
    tree \
    htop \
    build-essential \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDK 8.0
RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 8.0 --install-dir /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet

# Install PowerShell 7
RUN curl -sSL https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -o packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Create PowerShell module directory and set permissions
RUN mkdir -p /home/$USERNAME/.local/share/powershell/Modules \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/.local/share/powershell

# Switch to the non-root user
USER $USERNAME

# Set PowerShell as the default shell for the user
RUN echo 'exec pwsh -NoLogo' >> ~/.bashrc

# Install ONLY core PowerShell modules during build (for reliability)
RUN pwsh -NoProfile -Command \
    'Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    $coreModules = @("PowerShellGet", "PackageManagement", "PSReadLine"); \
    foreach ($module in $coreModules) { \
    Write-Host "Installing core module: $module"; \
    Install-Module -Name $module -Scope AllUsers -Force -AllowClobber; \
    }'

# Set up .NET global tools
RUN dotnet tool install --global dotnet-reportgenerator-globaltool --version 5.2.0 \
    && dotnet tool install --global coverlet.console --version 6.0.0 \
    && dotnet tool install --global dotnet-format --version 5.1.250801 \
    && dotnet tool install --global dotnet-outdated-tool --version 4.6.0

# Configure Git (will be overridden by user settings)
RUN git config --global init.defaultBranch main \
    && git config --global core.autocrlf input \
    && git config --global core.eol lf

# Create workspace directory and set appropriate permissions
WORKDIR /workspaces/OSDCloudCustomBuilder
RUN sudo chown -R $USERNAME:$USERNAME /workspaces

# Create a utility script for finding available ports
RUN echo '#!/usr/bin/env pwsh\n\
    function Find-AvailablePorts {\n\
    param([int]$StartPort = 3000, [int]$Count = 3)\n\
    $availablePorts = @()\n\
    $currentPort = $StartPort\n\
    while ($availablePorts.Count -lt $Count) {\n\
    $tcpListener = New-Object System.Net.Sockets.TcpListener $currentPort\n\
    try {\n\
    $tcpListener.Start()\n\
    $availablePorts += $currentPort\n\
    Write-Host "Port $currentPort is available"\n\
    } catch {\n\
    Write-Host "Port $currentPort is in use"\n\
    } finally {\n\
    $tcpListener.Stop()\n\
    }\n\
    $currentPort++\n\
    }\n\
    return $availablePorts\n\
    }\n\
    \n\
    $ports = Find-AvailablePorts -StartPort 3000 -Count 3\n\
    Write-Host "Available ports: $ports"\n\
    return $ports\n\
    ' | sudo tee /usr/local/bin/find-ports.ps1 > /dev/null \
    && sudo chmod +x /usr/local/bin/find-ports.ps1

# Expose ports - a range instead of specific ones
EXPOSE 3000-5002 8080-8090

# Set the default command
CMD ["pwsh", "-NoLogo"]
