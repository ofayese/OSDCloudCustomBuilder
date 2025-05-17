# Start-DevContainer.ps1
# This script builds and starts the OSDCloud development container

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$Rebuild,
    
    [Parameter()]
    [switch]$NoCache,
    
    [Parameter()]
    [switch]$Interactive
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Status {
    param (
        [string]$Message
    )
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" -ForegroundColor Cyan
}

try {
    # Check if Docker is installed
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is not installed or not in PATH. Please install Docker Desktop."
        exit 1
    }

    # Check if Docker is running
    try {
        $null = docker info
    }
    catch {
        Write-Error "Docker is not running. Please start Docker Desktop."
        exit 1
    }

    # Build arguments
    $buildArgs = @('compose', '-f', '.devcontainer/docker-compose.yml', 'build')
    
    if ($Rebuild) {
        Write-Status "Forcing rebuild of container"
        $buildArgs += '--no-cache'
    }
    elseif ($NoCache) {
        Write-Status "Building without cache"
        $buildArgs += '--no-cache'
    }

    # Build the container
    Write-Status "Building OSDCloud development container"
    & docker $buildArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build container. Exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }

    # Run the container
    Write-Status "Starting OSDCloud development container"
    
    if ($Interactive) {
        Write-Status "Starting in interactive mode"
        & docker compose -f .devcontainer/docker-compose.yml run --rm osdcloud-dev pwsh
    }
    else {
        & docker compose -f .devcontainer/docker-compose.yml up -d
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to start container. Exit code: $LASTEXITCODE"
            exit $LASTEXITCODE
        }
        
        Write-Status "Container started successfully"
        Write-Host ""
        Write-Host "To connect to the container:" -ForegroundColor Green
        Write-Host "  docker exec -it osdcloud-dev pwsh" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To stop the container:" -ForegroundColor Green
        Write-Host "  docker compose -f .devcontainer/docker-compose.yml down" -ForegroundColor Yellow
        Write-Host ""
    }
}
catch {
    Write-Error "Error: $_"
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
