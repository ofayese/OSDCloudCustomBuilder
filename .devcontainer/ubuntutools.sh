#!/bin/bash

# Enhanced Ubuntu tools installation for OSDCloudCustomBuilder DevContainer
# This script installs development tools and sets up the Ubuntu environment
# for optimal PowerShell and .NET development experience.

set -e

echo "🔧 Setting up Ubuntu development environment for OSDCloudCustomBuilder..."
echo "================================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}📘 $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Update package lists
print_info "Updating package lists..."
sudo apt update

# Upgrade existing packages
print_info "Upgrading existing packages..."
sudo apt upgrade -y

# Install essential build tools and dependencies
print_info "Installing essential development tools..."
sudo apt install -y \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    git \
    git-lfs \
    gh \
    nano \
    vim \
    curl \
    wget \
    unzip \
    zip \
    tar \
    gzip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    software-properties-common \
    lsb-release \
    jq \
    yq \
    bash-completion \
    zsh \
    fish \
    net-tools \
    dnsutils \
    iputils-ping \
    traceroute \
    nmap \
    tcpdump \
    htop \
    btop \
    tree \
    fd-find \
    ripgrep \
    bat \
    exa \
    tldr \
    tmux \
    screen \
    openssl \
    sqlite3 \
    postgresql-client \
    mysql-client \
    redis-tools

print_status "Essential tools installed"

# Install Python development tools
print_info "Installing Python development environment..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    python3-wheel \
    pipx

# Install useful Python packages
print_info "Installing Python utility packages..."
pip3 install --user \
    httpie \
    requests \
    pyyaml \
    toml \
    click \
    rich \
    typer \
    pytest \
    black \
    flake8 \
    mypy

print_status "Python environment configured"

# Install Node.js and npm (useful for documentation and web tools)
print_info "Installing Node.js environment..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Install useful npm packages globally
sudo npm install -g \
    markdownlint-cli \
    prettier \
    eslint \
    typescript \
    live-server \
    http-server

print_status "Node.js environment configured"

# Add Microsoft repository for PowerShell and .NET
print_info "Adding Microsoft package repository..."
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl -sSL https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -o packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package lists with Microsoft repository
sudo apt update

# Install PowerShell 7
print_info "Installing PowerShell 7..."
sudo apt install -y powershell

# Install .NET SDK (multiple versions for compatibility)
print_info "Installing .NET SDK..."
sudo apt install -y \
    dotnet-sdk-6.0 \
    dotnet-sdk-7.0 \
    dotnet-sdk-8.0 \
    aspnetcore-runtime-6.0 \
    aspnetcore-runtime-7.0 \
    aspnetcore-runtime-8.0

print_status "Microsoft development tools installed"

# Install Docker CLI (for container testing scenarios)
print_info "Installing Docker CLI..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce-cli docker-compose-plugin

print_status "Docker CLI installed"

# Install additional development tools
print_info "Installing additional development tools..."
sudo apt install -y \
    shellcheck \
    yamllint \
    ansible \
    terraform \
    vault \
    consul

# Install Azure CLI
print_info "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

print_status "Azure CLI installed"

# Install GitHub CLI authentication
print_info "Configuring GitHub CLI..."
gh --version

# Install Rust (for modern CLI tools)
print_info "Installing Rust toolchain..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Install useful Rust-based tools
cargo install \
    ripgrep \
    fd-find \
    bat \
    exa \
    tokei \
    hyperfine \
    bottom

print_status "Rust toolchain and tools installed"

# Configure Git with useful defaults
print_info "Configuring Git with development-friendly defaults..."
git config --global init.defaultBranch main
git config --global core.autocrlf input
git config --global core.eol lf
git config --global pull.rebase false
git config --global push.default simple
git config --global core.editor "nano"
git config --global diff.tool "code --wait --diff"
git config --global merge.tool "code --wait"

# Set up Git LFS
git lfs install

print_status "Git configured"

# Install Oh My Zsh for enhanced shell experience (optional)
print_info "Installing Oh My Zsh for enhanced shell experience..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Install useful plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    # Configure .zshrc with useful plugins
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker dotnet)/' ~/.zshrc

    print_status "Oh My Zsh installed and configured"
else
    print_info "Oh My Zsh already installed"
fi

# Create useful aliases
print_info "Setting up development aliases..."
cat >> ~/.bashrc << 'EOF'

# OSDCloudCustomBuilder Development Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# .NET aliases
alias dr='dotnet run'
alias db='dotnet build'
alias dt='dotnet test'
alias dc='dotnet clean'
alias dp='dotnet publish'

# PowerShell aliases
alias ps='pwsh'
alias pester='pwsh -Command Invoke-Pester'
alias analyze='pwsh -Command Invoke-ScriptAnalyzer'

# Docker aliases
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'

# Utility aliases
alias h='history'
alias c='clear'
alias x='exit'
alias reload='source ~/.bashrc'
EOF

# Also add to zshrc if it exists
if [ -f ~/.zshrc ]; then
    cat >> ~/.zshrc << 'EOF'

# OSDCloudCustomBuilder Development Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# .NET aliases
alias dr='dotnet run'
alias db='dotnet build'
alias dt='dotnet test'
alias dc='dotnet clean'
alias dp='dotnet publish'

# PowerShell aliases
alias ps='pwsh'
alias pester='pwsh -Command Invoke-Pester'
alias analyze='pwsh -Command Invoke-ScriptAnalyzer'
EOF
fi

print_status "Development aliases configured"

# Clean up package cache
print_info "Cleaning up package cache..."
sudo apt autoremove -y
sudo apt autoclean

# Verify installations
print_info "Verifying installations..."
echo ""
echo "🔍 Installation Verification:"
echo "=============================="

# Function to check command and version
check_command() {
    if command -v $1 &> /dev/null; then
        version=$($1 --version 2>/dev/null | head -n 1 || echo "installed")
        print_status "$1: $version"
    else
        print_error "$1: Not found"
    fi
}

check_command git
check_command gh
check_command pwsh
check_command dotnet
check_command docker
check_command az
check_command node
check_command npm
check_command python3
check_command pip3
check_command ansible
check_command terraform
check_command rustc
check_command cargo

# PowerShell specific checks
print_info "PowerShell environment check..."
pwsh -NoProfile -Command "
    Write-Host '  PowerShell Version:' \$PSVersionTable.PSVersion
    Write-Host '  PowerShell Edition:' \$PSVersionTable.PSEdition
    Write-Host '  OS:' \$PSVersionTable.OS
"

# .NET specific checks
print_info ".NET environment check..."
dotnet --list-sdks | while read line; do
    print_status "  SDK: $line"
done

dotnet --list-runtimes | while read line; do
    print_status "  Runtime: $line"
done

echo ""
print_status "Ubuntu development environment setup complete!"
echo ""
echo "🎉 Your development environment is ready!"
echo "📋 Next steps:"
echo "   1. Reload your shell: source ~/.bashrc"
echo "   2. Test PowerShell: pwsh"
echo "   3. Test .NET: dotnet --version"
echo "   4. Configure Git: git config --global user.name 'Your Name'"
echo "   5. Configure Git: git config --global user.email 'your.email@example.com'"
echo ""
echo "💡 Useful commands:"
echo "   pwsh                    - Start PowerShell"
echo "   dotnet --help           - .NET CLI help"
echo "   gh auth login           - Authenticate with GitHub"
echo "   az login                - Authenticate with Azure"
echo ""
print_status "Happy coding! 🚀"
