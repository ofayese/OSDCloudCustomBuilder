FROM mcr.microsoft.com/powershell/test-deps:lts-ubuntu-22.04

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    wget \
    apt-transport-https \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Set up PowerShell modules directory
RUN mkdir -p /usr/local/share/powershell/Modules

# Create a non-root user to use if preferred
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # Add sudo support
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch to vscode user
USER $USERNAME

# Create workspace directory and set up PowerShell profile
RUN mkdir -p /home/$USERNAME/.config/powershell \
    && echo "# PowerShell Profile for OSDCloudCustomBuilder testing" > /home/$USERNAME/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo "Write-Host 'OSDCloudCustomBuilder Test Environment' -ForegroundColor Cyan" >> /home/$USERNAME/.config/powershell/Microsoft.PowerShell_profile.ps1

# Set the default shell to PowerShell
SHELL ["pwsh", "-Command"]

# Install PowerShell modules needed for testing
RUN Install-Module Pester -Force -SkipPublisherCheck; \
    Install-Module ThreadJob -Force; \
    Install-Module PSScriptAnalyzer -Force

# Set the default shell back to bash for compatibility with VS Code
SHELL ["/bin/bash", "-c"]

WORKDIR /workspace
