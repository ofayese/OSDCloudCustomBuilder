FROM mcr.microsoft.com/powershell:latest

RUN apt-get update && \
    apt-get install -y \
    git \
    curl \
    unzip \
    vim \
    nano \
    less \
    wget \
    gnupg \
    software-properties-common \
    lsb-release \
    ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m vscode
USER vscode
WORKDIR /home/vscode