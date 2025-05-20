<#
.SYNOPSIS
Starts Linux dev containers using a shared Docker volume. Copies internal files from container images into the volume before launch. WSL2-safe. Supports Docker Compose export.

.DESCRIPTION
- Only Linux containers (safe for WSL2)
- Uses docker cp + alpine to copy internal files from each image into a shared volume
- Runs containers (interactive or sleep)
- Can export docker-compose.yml

.NOTES
Target: Windows 11 + Docker Desktop (WSL2, Linux container mode)
#>

[CmdletBinding()]
param (
    [string]$VolumeName = "wsl2-dev-volume",
    [int]$ContainerTimeout = 3600,
    [switch]$InteractiveShell,
    [switch]$ExportCompose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$script:failedContainers = @()
$ComposeServices = @{}

# Map of image → internal paths to copy
$FileMap = @{
    "ai/mistral:latest"                     = @("/models")
    "sourcegraph/frontend:insiders"         = @("/app", "/etc/sourcegraph")
    "sourcegraph/sourcegraph-dev:insiders"  = @("/etc/sourcegraph", "/app")
    "default"                               = @("/app", "/etc", "/usr/share")
}

$dockerImages = @(
    "mcr.microsoft.com/powershell:latest",
    "mcr.microsoft.com/powershell:preview-7.6-ubuntu-24.04",
    "mcr.microsoft.com/azure-powershell:ubuntu-22.04",
    "mcr.microsoft.com/powershell/test-deps:debian-12",
    "mcr.microsoft.com/powershell/test-deps:lts-ubuntu-22.04",

    "ai/deepcoder-preview",
    "ai/llama3.2:latest",
    "ai/mistral:latest",

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
    "mcp/time",

    "sourcegraph/cody-gateway:insiders",
    "sourcegraph/executor:insiders",
    "sourcegraph/executor-vm:insiders",
    "sourcegraph/frontend:insiders",
    "sourcegraph/github-proxy:insiders",
    "sourcegraph/gitserver:insiders",
    "sourcegraph/indexed-searcher:insiders",
    "sourcegraph/initcontainer:insiders",
    "sourcegraph/node-exporter:insiders",
    "sourcegraph/opentelemetry-collector:insiders",
    "sourcegraph/redis-cache:insiders",
    "sourcegraph/redis_exporter:insiders",
    "sourcegraph/repo-updater:insiders",
    "sourcegraph/search-indexer:insiders",
    "sourcegraph/searcher:insiders",
    "sourcegraph/jaeger-agent:insiders",
    "sourcegraph/jaeger-all-in-one:insiders",
    "sourcegraph/sourcegraph-dev:insiders",
    "sourcegraph/sourcegraph-toolbox:insiders",
    "sourcegraph/symbols:insiders",

    "containrrr/watchtower",
    "curlimages/curl",
    "postgres",
    "redis",
    "node",
    "python"
)

function Test-DockerLinuxMode {
    try {
        $osType = docker info --format '{{.OSType}}'
        if ($osType -ne 'linux') {
            Write-Warning "Docker is in Windows container mode. Please switch to Linux containers for WSL2 compatibility."
            return $false
        }
        return $true
    }
    catch {
        Write-Error "Docker is unavailable or not responding."
        return $false
    }
}

function New-SharedDockerVolume {
    param ([string]$Name)
    if (-not (docker volume ls --format "{{.Name}}" | Where-Object { $_ -eq $Name })) {
        Write-Host "[+] Creating Docker volume: $Name"
        docker volume create $Name | Out-Null
    }
    else {
        Write-Host "[=] Docker volume already exists: $Name"
    }
}

function Copy-FromImageToVolume {
    param (
        [string]$Image,
        [string]$VolumeName,
        [string[]]$PathsInImage
    )

    $safeId = ($Image -replace '[^a-zA-Z0-9]', '_')
    $tempContainer = "temp_${safeId}_$(Get-Random)"

    try {
        Write-Host "[>] Creating temporary container: $tempContainer from $Image"
        docker create --name $tempContainer $Image sleep infinity | Out-Null

        foreach ($srcPath in $PathsInImage) {
            Write-Host "    [+] Copying $srcPath from $Image"
            try {
                docker cp "$tempContainer : $srcPath" - |
                    docker run --rm -i -v "${VolumeName}:/shared" alpine sh -c "tar -x -C /shared"
            }
            catch {
                Write-Warning "    [!] Failed to copy $srcPath from $Image"
            }
        }
    }
    catch {
        Write-Warning "    [!] Could not inspect $Image : $_"
    }
    finally {
        docker rm $tempContainer -f | Out-Null
    }
}

function Start-DevContainer {
    param (
        [string]$Image,
        [string]$VolumeName,
        [int]$Timeout,
        [switch]$Interactive
    )

    $safeName = $Image -replace "[/:]", "_"
    $containerName = "wsl2dev_$safeName"

    if (docker ps -a --format '{{.Names}}' | Where-Object { $_ -eq $containerName }) {
        Write-Host "[=] Container exists: $containerName - skipping"
        return
    }

    try {
        Write-Host "[+] Pulling image: $Image"
        docker pull $Image | Out-Null

        $cmd = if ($Interactive) { "sh -c 'bash || sh'" } else { "sleep $Timeout" }

        docker run -d `
            --name $containerName `
            --label "stack=wsl2-dev" `
            --label "source_image=$Image" `
            -v "${VolumeName}:/shared" `
            $Image $cmd | Out-Null

        # Compose data
        $ComposeServices[$containerName] = @{
            image = $Image
            container_name = $containerName
            volumes = @("${VolumeName}:/shared")
            command = $cmd
        }

        Write-Host "[✓] Started container: $containerName"
    }
    catch {
        Write-Warning "    [!] Failed to start container for image '$Image': $_"
        $script:failedContainers += $Image
    }
}

function Export-DockerCompose {
    param (
        [string]$VolumeName,
        [hashtable]$Services
    )

    $yaml = @()
    $yaml += "version: '3.8'"
    $yaml += "services:"

    foreach ($name in $Services.Keys) {
        $svc = $Services[$name]
        $yaml += "  $name :"
        $yaml += "    image: ${svc.image}"
        $yaml += "    container_name: ${svc.container_name}"
        $yaml += "    volumes:"
        foreach ($vol in $svc.volumes) {
            $yaml += "      - ${vol}"
        }
        $yaml += "    command: ${svc.command}"
    }

    $yaml += "volumes:"
    $yaml += "  $VolumeName :"
    Set-Content -Path "./docker-compose.yml" -Value ($yaml -join "`n") -Encoding UTF8
    Write-Host "`n[✓] Exported Docker Compose config to: ./docker-compose.yml"
}

# === MAIN EXECUTION ===
if (-not (Test-DockerLinuxMode)) { exit 1 }

New-SharedDockerVolume -Name $VolumeName

foreach ($image in $dockerImages) {
    $paths = $FileMap[$image] ? $FileMap[$image] : $FileMap["default"]
    Copy-FromImageToVolume -Image $image -VolumeName $VolumeName -PathsInImage $paths
    Start-DevContainer -Image $image -VolumeName $VolumeName -Timeout $ContainerTimeout -Interactive:$InteractiveShell
}

if ($ExportCompose) {
    Export-DockerCompose -VolumeName $VolumeName -Services $ComposeServices
}

if ($script:failedContainers.Count -gt 0) {
    Write-Warning "`n[!] The following containers failed to start:`n$($script:failedContainers -join "`n")"
} else {
    Write-Host "`n[✓] All containers started and use volume: $VolumeName"
}
