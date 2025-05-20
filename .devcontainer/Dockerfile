# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/powershell/test-deps:lts-ubuntu-22.04

# Install packages with BuildKit cache mounts
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        unzip \
        ca-certificates \
        apt-transport-https \
        software-properties-common \
        python3 \
        python3-pip \
        docker.io && \
    true

# Install PowerShell modules (batched in a single command for clarity)
RUN pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Name Pester -Force; Install-Module -Name PSScriptAnalyzer -Force; Install-Module -Name Az -Force; Install-Module -Name OSD -Force; Install-Module -Name WindowsAutoPilotIntune -Force"

# Prepare working directory
WORKDIR /workspace

# Create a secure non-root user with docker and sudo privileges
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    apt-get update && \
    apt-get install -y --no-install-recommends sudo && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME} && \
    usermod -aG docker ${USERNAME}

# Setup shared workspace directories with ownership
RUN install -d -o ${USERNAME} -g ${USERNAME} /shared/bin /shared/ai-tools /shared/mcp-tools

# Drop to non-root user
USER ${USERNAME}
