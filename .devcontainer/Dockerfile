FROM mcr.microsoft.com/powershell:latest

# Install necessary packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        git \
        curl \
        unzip \
        ca-certificates \
        apt-transport-https \
        software-properties-common \
        python3 \
        python3-pip \
        docker.io \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell modules
RUN pwsh -Command " \
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module -Name Pester -Force; \
    Install-Module -Name PSScriptAnalyzer -Force; \
    Install-Module -Name Az -Force; \
    Install-Module -Name OSD -Force; \
    Install-Module -Name WindowsAutoPilotIntune -Force"

# Create workspace directory
WORKDIR /workspace

# Create a non-root user for better security
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Add user to docker group
RUN usermod -aG docker $USERNAME

# Set up directory for tool integration
RUN mkdir -p /shared/bin /shared/ai-tools /shared/mcp-tools \
    && chown -R $USERNAME:$USERNAME /shared

# Switch to the non-root user
USER $USERNAME