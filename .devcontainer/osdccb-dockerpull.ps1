# Ensure Docker is available
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker CLI is not available. Please install Docker and try again."
    exit 1
}

# Initialize tracking arrays for summary report
$successfulContainers = @()
$failedContainers = @()

# Function to test if a container is healthy
function Test-ContainerHealth {
    param([string]$ContainerName)
    
    $containerInfo = docker inspect $ContainerName 2>$null | ConvertFrom-Json
    if (-not $containerInfo) { return $false }
    
    # Check if container is running
    if ($containerInfo.State.Status -ne "running") { return $false }
    
    # For containers with health checks
    if ($containerInfo.State.Health) {
        return $containerInfo.State.Health.Status -eq "healthy"
    }
    
    # If no health check, just verify it's running
    return $true
}

# Function to retry an operation
function Invoke-WithRetry {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [int]$MaxAttempts = 3,
        [int]$DelaySeconds = 5
    )
    
    $attempt = 1
    $success = $false
    
    while (-not $success -and $attempt -le $MaxAttempts) {
        try {
            if ($attempt -gt 1) {
                Write-Host "    Retry attempt $attempt of $MaxAttempts..."
            }
            
            & $ScriptBlock
            $success = $true
        }
        catch {
            if ($attempt -lt $MaxAttempts) {
                Write-Warning "    Attempt $attempt failed: $($_.Exception.Message). Retrying in $DelaySeconds seconds..."
                Start-Sleep -Seconds $DelaySeconds
            }
            else {
                Write-Warning "    All $MaxAttempts attempts failed. Last error: $($_.Exception.Message)"
                throw
            }
        }
        $attempt++
    }
}

# Define shared volume name
$volumeName = "osdccb-dev-volume"

# Create named volume if it doesn't exist
if (-not (docker volume ls --format "{{.Name}}" | Where-Object { $_ -eq $volumeName })) {
    Write-Host "[+] Creating Docker named volume: $volumeName"
    docker volume create $volumeName | Out-Null
} else {
    Write-Host "[=] Named volume already exists: $volumeName"
}

# Determine OS platform for proper volume mounting
$osdccbIsWindowsHost = $env:OS -eq 'Windows_NT' -or [System.Environment]::OSVersion.Platform -eq 'Win32NT'
$mountPath = if ($osdccbIsWindowsHost) { "C:/shared" } else { "/shared" }

# Define Docker image list
$dockerImages = @(
    # --- PowerShell Development ---
    "mcr.microsoft.com/powershell:latest"
    "mcr.microsoft.com/powershell:preview"
    "mcr.microsoft.com/powershell:preview-7.6-ubuntu-24.04"
    "mcr.microsoft.com/azure-powershell:ubuntu-22.04"
    "mcr.microsoft.com/powershell/test-deps:debian-12"
    "mcr.microsoft.com/powershell/test-deps:lts-ubuntu-22.04"
    "mcr.microsoft.com/dotnet/framework/runtime:4.8.1"
    "mcr.microsoft.com/dotnet/framework/sdk:4.8.1"

    # --- AI Tools ---
    "ai/deepcoder-preview"
    "ai/llama3.2:latest"
    "ai/mistral:latest"

    # --- MCP Tools ---
    "mcp/everything"
    "mcp/fetch"
    "mcp/filesystem"
    "mcp/git"
    "mcp/github"
    "mcp/gitlab"
    "mcp/memory"
    "mcp/postgres"
    "mcp/puppeteer"
    "mcp/sequentialthinking"
    "mcp/sentry"
    "mcp/sqlite"
    "mcp/time"

    # --- Sourcegraph Stack ---
    "sourcegraph/cody-gateway:insiders"
    "sourcegraph/executor:insiders"
    "sourcegraph/executor-vm:insiders"
    "sourcegraph/frontend:insiders"
    "sourcegraph/github-proxy:insiders"
    "sourcegraph/gitserver:insiders"
    "sourcegraph/indexed-searcher:insiders"
    "sourcegraph/initcontainer:insiders"
    "sourcegraph/node-exporter:insiders"
    "sourcegraph/opentelemetry-collector:insiders"
    "sourcegraph/redis-cache:insiders"
    "sourcegraph/redis_exporter:insiders"
    "sourcegraph/repo-updater:insiders"
    "sourcegraph/search-indexer:insiders"
    "sourcegraph/searcher:insiders"
    "sourcegraph/jaeger-agent:insiders"
    "sourcegraph/jaeger-all-in-one:insiders"
    "sourcegraph/sourcegraph-dev:insiders"
    "sourcegraph/sourcegraph-toolbox:insiders"
    "sourcegraph/symbols:insiders"

    # --- Utilities ---
    "containrrr/watchtower"
    "curlimages/curl"
    "postgres"
    "redis"
    "node"
    "python"
)

# Function to check if container should use PowerShell or bash for idle
function Get-IdleCommand {
    param([string]$Image)
    
    if ($Image -like "*powershell*" -or $Image -like "*dotnet*framework*") {
        return "powershell -Command `"while(`$true) { Start-Sleep -Seconds 60 }`""
    } elseif ($Image -like "*python*") {
        return "python -c 'import time; while True: time.sleep(60)'"
    } elseif ($Image -like "*node*") {
        return "node -e 'setInterval(() => {}, 60000)'"
    } else {
        return "sh -c 'while true; do sleep 60; done'"
    }
}

# Function to determine if image is a Windows container
function Test-WindowsContainer {
    param([string]$Image)
    
    return $Image -like "*windows*" -or $Image -like "*nanoserver*" -or $Image -like "*dotnet*framework*"
}

# Count for progress tracking
$totalImages = $dockerImages.Count
$currentImage = 0

# Launch each container with shared volume
foreach ($image in $dockerImages) {
    $currentImage++
    Write-Host "`n[>] Processing image [$currentImage/$totalImages]: $image"
    
    # Check if image exists locally first
    if (-not (docker image ls --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -eq $image -or ($_ -eq "$image:latest" -and $image -notlike "*:*") })) {
        try {
            Write-Host "    Pulling image: $image"
            docker pull $image
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "    Failed to pull image: $image. Continuing with next image."
                continue
            }
        }
        catch {
            Write-Warning "    Error pulling image: $image. $($_.Exception.Message)"
            continue
        }
    } else {
        Write-Host "    Image already exists locally: $image"
    }

    # Sanitize image name
    $safeName = $image -replace "[/:]", "_"
    $containerName = "dev_$safeName"

    # Skip existing containers
    if (docker ps -a --format '{{.Names}}' | Where-Object { $_ -eq $containerName }) {
        Write-Host "    Container already exists: $containerName - skipping"
        continue
    }

    Write-Host "    Running container: $containerName with shared volume"
    
    # Get appropriate idle command
    $idleCommand = Get-IdleCommand -Image $image
    
    # Set appropriate isolation flag based on platform and container type
    $isolationFlag = if (($env:OS -eq 'Windows_NT' -or [System.Environment]::OSVersion.Platform -eq 'Win32NT') -and (Test-WindowsContainer -Image $image)) { 
        "--isolation=process" 
    } elseif (($env:OS -eq 'Windows_NT' -or [System.Environment]::OSVersion.Platform -eq 'Win32NT') -and (-not (Test-WindowsContainer -Image $image))) {
        "--isolation=default"
    } else { 
        "" 
    }
    
    try {
        # Determine proper mount path based on container type
        $containerMountPath = if (Test-WindowsContainer -Image $image) { 
            # Windows containers need Windows-style paths
            "C:/shared"
        } else { 
            # Linux containers need Linux-style paths
            "/shared" 
        }
        
        # Increase resource limits and add restart policy
        $dockerRunCmd = "docker run -d " +
            "--name $containerName " +
            "--label `"source_image=$image`" " +
            "--label `"created_by=osdccb-script`" " +
            "--memory=512m " +
            "--memory-swap=1g " +
            "--cpus=1.0 " +
            "--restart=unless-stopped " +
            "-v `"${volumeName}:$containerMountPath`" "
            
        if ($isolationFlag) {
            $dockerRunCmd += "$isolationFlag "
        }
        
        $dockerRunCmd += "$image "
        
        # Handle command execution differently based on container type
        if ($idleCommand) {
            $dockerRunCmd += "$idleCommand"
        }
        
        Write-Host "    Executing: $dockerRunCmd"
        
        # Use retry mechanism for container creation
        Invoke-WithRetry -ScriptBlock {
            Invoke-Expression $dockerRunCmd
            if ($LASTEXITCODE -ne 0) {
                throw "Docker run failed with exit code $LASTEXITCODE"
            }
        } -MaxAttempts 2 -DelaySeconds 3

        # Give the container a moment to initialize
        Start-Sleep -Seconds 2

        # Verify container is actually running
        if (Test-ContainerHealth -ContainerName $containerName) {
            Write-Host "    Container started successfully and is healthy: $containerName" -ForegroundColor Green
            $successfulContainers += @{Name = $containerName; Image = $image}
        } else {
            $containerStatus = docker ps -f "name=$containerName" --format "{{.Status}}"
            if ($containerStatus) {
                Write-Host "    Container started but health check pending: $containerName" -ForegroundColor Yellow
                $successfulContainers += @{Name = $containerName; Image = $image; Status = "Started (health pending)"}
            } else {
                Write-Warning "    Container created but not running. Checking container status..."
                $containerInfo = docker inspect $containerName | ConvertFrom-Json
                Write-Warning "    Container state: $($containerInfo.State.Status)"
                if ($containerInfo.State.ExitCode -ne 0) {
                    Write-Warning "    Exit code: $($containerInfo.State.ExitCode)"
                    Write-Warning "    Error: $($containerInfo.State.Error)"
                }
                $failedContainers += @{Name = $containerName; Image = $image; Error = "Exit code: $($containerInfo.State.ExitCode)"}
            }
        }
    }
    catch {
        Write-Warning "    Error creating container: $containerName. $($_.Exception.Message)"
        $failedContainers += @{Name = $containerName; Image = $image; Error = $_.Exception.Message}
        
        # Try to get more information about what went wrong
        try {
            $containerExists = docker ps -a -f "name=$containerName" --format "{{.Names}}"
            if ($containerExists) {
                Write-Warning "    Container exists but may have failed to start. Checking logs..."
                $logs = docker logs $containerName 2>&1
                if ($logs) {
                    Write-Warning "    Container logs: $logs"
                }
            }
        } catch {
            Write-Warning "    Could not retrieve additional error information: $($_.Exception.Message)"
        }
    }
}

# Display summary report
Write-Host "`n===== CONTAINER DEPLOYMENT SUMMARY ====="
Write-Host "Total containers attempted: $($dockerImages.Count)"
Write-Host "Successfully started: $($successfulContainers.Count)" -ForegroundColor Green
Write-Host "Failed to start: $($failedContainers.Count)" -ForegroundColor $(if ($failedContainers.Count -gt 0) { "Red" } else { "Green" })

if ($failedContainers.Count -gt 0) {
    Write-Host "`nFailed containers:" -ForegroundColor Red
    foreach ($container in $failedContainers) {
        Write-Host "  - $($container.Name) (Image: $($container.Image))" -ForegroundColor Red
        Write-Host "    Error: $($container.Error)" -ForegroundColor Red
    }
    
    Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Check if the image exists and is compatible with your system"
    Write-Host "2. Verify Docker has sufficient resources (memory, disk space)"
    Write-Host "3. For Windows containers, ensure Hyper-V or WSL2 is properly configured"
    Write-Host "4. Check if the container requires additional environment variables"
}

Write-Host "`n✅ Dev containers launched using shared named volume: $volumeName"
Write-Host "👉 To clean up all containers created by this script:"
Write-Host "   docker rm -f `$(docker ps -aq --filter 'label=created_by=osdccb-script')"
Write-Host "👉 To view running containers:"
Write-Host "   docker ps --filter 'label=created_by=osdccb-script'"
