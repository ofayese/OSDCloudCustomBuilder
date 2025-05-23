# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/powershell/test-deps:lts-ubuntu-22.04

# Install packages with BuildKit cache mounts
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
        git \
        gh \
        curl \
        unzip \
        ca-certificates \
        apt-transport-https \
        software-properties-common \
        python3 \
        python3-pip \
        docker.io \
        jq \
        bash-completion \
        less \
        vim && \
    rm -rf /var/lib/apt/lists/*

# Install PowerShell modules efficiently (multiple modules in a single command)
RUN pwsh -Command "\
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    \$modules = @('Pester', 'PSScriptAnalyzer', 'PSDepend', 'InvokeBuild', 'ModuleBuilder', 'OSD', 'Az'); \
    Install-Module -Name \$modules -Force -Scope AllUsers -SkipPublisherCheck; \
    Find-Module -Name WindowsAutoPilotIntune | Install-Module -Force -Scope AllUsers"

# Create a shared development directory
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

# Setup project directory structure
RUN mkdir -p /workspace/src /workspace/tests /workspace/tools /workspace/out && \
    chown -R ${USERNAME}:${USERNAME} /workspace

# Drop to non-root user
USER ${USERNAME}

# Add bash and PowerShell configuration for better development experience
RUN echo 'export PROMPT_DIRTRIM=2' >> ~/.bashrc && \
    echo 'export PS1="\[\e[32m\]\u@dev-container\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ "' >> ~/.bashrc && \
    mkdir -p ~/.config/powershell && \
    echo 'Set-PSReadLineOption -HistorySearchCursorMovesToEnd -PredictionSource History' > ~/.config/powershell/Microsoft.PowerShell_profile.ps1 && \
    echo 'Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward' >> ~/.config/powershell/Microsoft.PowerShell_profile.ps1 && \
    echo 'Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward' >> ~/.config/powershell/Microsoft.PowerShell_profile.ps1 && \
    echo 'function prompt {"PS $($executionContext.SessionState.Path.CurrentLocation)$(''>'' * ($nestedPromptLevel + 1)) "}' >> ~/.config/powershell/Microsoft.PowerShell_profile.ps1
