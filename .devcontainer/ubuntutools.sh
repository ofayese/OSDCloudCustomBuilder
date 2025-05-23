#!/bin/bash

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install essential developer tools
sudo apt install -y \
    build-essential \
    git \
    gh \
    nano \
    curl \
    wget \
    unzip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    software-properties-common \
    lsb-release \
    jq \
    bash-completion \
    net-tools \
    dnsutils \
    openssl

# Optional: Install Python tools
sudo apt install -y python3 python3-pip python3-venv

# Add Microsoft repository for PowerShell (correct for Ubuntu 22.04)
curl -sSL https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -o packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update again after adding Microsoft repo
sudo apt update

# Install the latest PowerShell
sudo apt install -y powershell

# Verify installations
echo "✅ Installed versions:"
git --version
gh --version
nano --version
pwsh --version

echo -e "\n✅ All tools installed successfully."
