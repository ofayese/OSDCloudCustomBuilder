# Ensure Docker is available
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker CLI is not available. Please install Docker and try again."
    exit 1
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
$mountPath = if ($env:OS -eq 'Windows_NT' -or [System.Environment]::OSVersion.Platform -eq 'Win32NT') { "C:\shared" } else { "/shared" }

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
        return "powershell -Command `"Start-Sleep -Seconds 3600`""
    } else {
        return "sh -c 'sleep 3600'"
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
    } else { 
        "" 
    }
    
    try {
        docker run -d `
            --name $containerName `
            --label "stack=dev" `
            --label "source_image=$image" `
            --label "created_by=osdccb-script" `
            --memory="256m" `
            --cpus="0.5" `
            -v "${volumeName}:$mountPath" `
            $isolationFlag `
            $image `
            $idleCommand
            
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "    Failed to start container: $containerName"
        }
    }
    catch {
        Write-Warning "    Error creating container: $containerName. $($_.Exception.Message)"
    }
}

Write-Host "`n✅ All dev containers launched using shared named volume: $volumeName"
Write-Host "👉 To clean up all containers created by this script:"
Write-Host "   docker rm -f `$(docker ps -aq --filter 'label=created_by=osdccb-script')"
