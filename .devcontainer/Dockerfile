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

# Switch to the non-root user
USER $USERNAME

# Set PowerShell as the default shell for the user
RUN echo 'exec pwsh -NoLogo' >> ~/.bashrc

# Install PowerShell modules for development and testing
RUN pwsh -NoProfile -Command \
    'Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    $modules = @( \
        @{Name="Pester"; Version="5.5.0"}, \
        @{Name="PSScriptAnalyzer"; Version="1.21.0"}, \
        @{Name="PSReadLine"; Version="2.3.4"}, \
        @{Name="PSFramework"; Version="1.7.270"}, \
        @{Name="PSDepend"; Version="0.3.8"}, \
        @{Name="InvokeBuild"; Version="5.10.4"}, \
        @{Name="ModuleBuilder"; Version="2.0.0"}, \
        @{Name="PSModuleDevelopment"; Version="2.2.9.94"}, \
        @{Name="Plaster"; Version="1.1.3"}, \
        @{Name="PowerShellGet"; Version="2.2.5"}, \
        @{Name="PackageManagement"; Version="1.4.8.1"}, \
        @{Name="PSRule"; Version="2.9.0"}, \
        @{Name="PSRule.Rules.Azure"; Version="1.30.1"}, \
        @{Name="OSD"; Version="23.5.26.1"}, \
        @{Name="PowerShellProTools"; Version="5.8.6"} \
    ); \
    foreach ($module in $modules) { \
        Write-Host "Installing $($module.Name) v$($module.Version)..."; \
        try { \
            Install-Module -Name $module.Name -RequiredVersion $module.Version -Scope AllUsers -Force -AllowClobber -ErrorAction Stop; \
            Write-Host "✅ $($module.Name) installed successfully"; \
        } catch { \
            Write-Warning "❌ Failed to install $($module.Name): $_"; \
        } \
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

# Expose ports for potential web interfaces or debugging
EXPOSE 8080 5000 5001

# Set the default command
CMD ["pwsh", "-NoLogo"]
