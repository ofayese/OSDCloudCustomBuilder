# Bootstrap script for OSDCloudCustomBuilder test environment
[CmdletBinding()]
param (
    [switch]$RunTests,
    [switch]$BuildContainer,
    [switch]$UsePrebuiltImage
)

Write-Host "Bootstrapping OSDCloudCustomBuilder test environment..." -ForegroundColor Cyan

# Check if Docker is installed
try {
    $dockerVersion = docker --version
    Write-Host "Docker detected: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "Docker not found. Please install Docker before continuing." -ForegroundColor Red
    exit 1
}

# Make sure devcontainer directory exists
$devContainerPath = Join-Path -Path $PSScriptRoot -ChildPath ".devcontainer"
if (-not (Test-Path -Path $devContainerPath)) {
    Write-Host "Error: .devcontainer directory not found!" -ForegroundColor Red
    exit 1
}

# Create OSDCloud directory structure if it doesn't exist
$osdCloudDir = Join-Path -Path $PSScriptRoot -ChildPath "OSDCloud"
if (-not (Test-Path -Path $osdCloudDir)) {
    Write-Host "Creating OSDCloud directory structure..." -ForegroundColor Yellow
    New-Item -Path $osdCloudDir -ItemType Directory -Force | Out-Null
    Write-Host "OSDCloud directory created" -ForegroundColor Green
}

if ($BuildContainer) {
    # Build the container
    Write-Host "Building test container..." -ForegroundColor Yellow
    docker-compose -f "$devContainerPath/docker-compose.yml" build
}

# Start the environment
Write-Host "Starting test environment..." -ForegroundColor Yellow
docker-compose -f "$devContainerPath/docker-compose.yml" up -d

# Wait for container to be ready
Write-Host "Waiting for container to be fully initialized..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Run the setup script inside the container
Write-Host "Setting up test environment inside container..." -ForegroundColor Yellow
docker exec osdcloud-powershell pwsh -Command "/workspace/.devcontainer/setup-test-environment.ps1"

# Run tests if requested
if ($RunTests) {
    Write-Host "Running tests..." -ForegroundColor Yellow
    docker exec osdcloud-powershell pwsh -Command "/workspace/Run-Tests.ps1"
}

Write-Host "Test environment is ready!" -ForegroundColor Green
Write-Host "You can now work with the environment using VS Code's 'Reopen in Container' feature" -ForegroundColor Cyan
Write-Host "or connect directly to the container with:" -ForegroundColor Cyan
Write-Host "  docker exec -it osdcloud-powershell pwsh" -ForegroundColor White
