#Requires -Version 7.0

# Setup script to configure access to MCP tools, AI tools, and PowerShell test dependencies
Write-Host "Setting up specialized tools for development environment..." -ForegroundColor Cyan

# Create directories for tools
$sharedDir = "/shared"
$aiToolsDir = "$sharedDir/ai-tools"
$mcpToolsDir = "$sharedDir/mcp-tools"
$binDir = "$sharedDir/bin"

# Ensure directories exist
New-Item -Path $aiToolsDir, $mcpToolsDir, $binDir -ItemType Directory -Force | Out-Null

Write-Host "• Creating tool wrappers for AI Tools..." -ForegroundColor Yellow
# Create wrapper scripts for AI tools
$aiImages = @(
    "ai/deepcoder-preview",
    "ai/llama3.2:latest",
    "ai/mistral:latest"
)

foreach ($image in $aiImages) {
    $toolName = ($image -split "/")[1] -split ":" | Select-Object -First 1
    $wrapperPath = "$binDir/$toolName"

@"
#!/bin/bash
# Wrapper for $image
docker run --rm -i -v \`pwd\`:/workspace -w /workspace $image "\$@"
"@ | Out-File -FilePath $wrapperPath -Encoding utf8 -Force

    # Make executable
    chmod +x $wrapperPath
    Write-Host "  - Created wrapper for $toolName"
}

Write-Host "• Creating tool wrappers for MCP Tools..." -ForegroundColor Yellow
# Create wrapper scripts for MCP tools
$mcpImages = @(
    "mcp/everything",
    "mcp/fetch",
    "mcp/filesystem",
    "mcp/git",
    "mcp/github",
    "mcp/gitlab",
    "mcp/memory",
    "mcp/postgres",
    "mcp/puppeteer",
    "mcp/sequentialthinking",
    "mcp/sentry",
    "mcp/sqlite",
    "mcp/time"
)

foreach ($image in $mcpImages) {
    $toolName = ($image -split "/")[1]
    $wrapperPath = "$binDir/mcp-$toolName"

@"
#!/bin/bash
# Wrapper for $image
docker run --rm -i -v \`pwd\`:/workspace -w /workspace $image "\$@"
"@ | Out-File -FilePath $wrapperPath -Encoding utf8 -Force

    # Make executable
    chmod +x $wrapperPath
    Write-Host "  - Created wrapper for mcp-$toolName"
}

Write-Host "• Setting up PowerShell test environments..." -ForegroundColor Yellow
# Configure PowerShell test environments
$testEnvImages = @(
    "mcr.microsoft.com/powershell/test-deps:debian-12",
    "mcr.microsoft.com/powershell/test-deps:lts-ubuntu-22.04"
)

foreach ($image in $testEnvImages) {
    $envName = ($image -split ":")[1]
    $wrapperPath = "$binDir/pwsh-test-$envName"

@"
#!/bin/bash
# Test environment for PowerShell using $image
docker run --rm -it -v \`pwd\`:/workspace -w /workspace $image pwsh "\$@"
"@ | Out-File -FilePath $wrapperPath -Encoding utf8 -Force

    # Make executable
    chmod +x $wrapperPath
    Write-Host "  - Created test environment: pwsh-test-$envName"
}

# Create readme file with usage instructions
@"
# Dev Environment Tools

This directory contains tools accessible within your development environment.

## AI Tools
- llama3.2 - Run large language model inference
- mistral - Run Mistral inference
- deepcoder-preview - Code generation with DeepCoder

## MCP Tools
- mcp-everything - Combined MCP capabilities
- mcp-fetch - Fetch web content
- mcp-filesystem - File operations
- mcp-git - Git operations
- mcp-github - GitHub integration
- mcp-gitlab - GitLab integration
- mcp-memory - Memory management
- mcp-postgres - PostgreSQL operations
- mcp-puppeteer - Web automation
- mcp-sequentialthinking - Sequential reasoning
- mcp-sentry - Error reporting
- mcp-sqlite - SQLite operations
- mcp-time - Time utilities

## PowerShell Test Environments
- pwsh-test-debian-12 - Test on Debian 12
- pwsh-test-lts-ubuntu-22.04 - Test on Ubuntu 22.04 LTS

All tools are in your PATH and can be run directly from terminal.
"@ | Out-File -FilePath "$sharedDir/TOOLS-README.md" -Encoding utf8 -Force

Write-Host "✅ All tools configured successfully!" -ForegroundColor Green
Write-Host "The tools are available in your PATH. See /shared/TOOLS-README.md for details." -ForegroundColor Cyan
