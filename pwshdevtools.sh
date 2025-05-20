#!/usr/bin/env bash
set -euo pipefail

VOLUME_NAME="${1:-wsl2-dev-volume}"
CONTAINER_TIMEOUT="${2:-3600}"
INTERACTIVE=false
EXPORT_COMPOSE=false
FAILED_CONTAINERS=()
declare -A COMPOSE_SERVICES

# List of images
DOCKER_IMAGES=(
  "mcr.microsoft.com/powershell:latest"
  "mcr.microsoft.com/powershell:preview-7.6-ubuntu-24.04"
  "mcr.microsoft.com/azure-powershell:ubuntu-22.04"
  "mcr.microsoft.com/powershell/test-deps:debian-12"
  "mcr.microsoft.com/powershell/test-deps:lts-ubuntu-22.04"
  "ai/deepcoder-preview"
  "ai/llama3.2:latest"
  "ai/mistral:latest"
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
  "containrrr/watchtower"
  "curlimages/curl"
  "postgres"
  "redis"
  "node"
  "python"
)

# Check for Docker in Linux container mode
check_docker_linux_mode() {
  if [[ "$(docker info --format '{{.OSType}}')" != "linux" ]]; then
    echo "❌ Docker is not in Linux mode. Please switch for WSL2 compatibility."
    exit 1
  fi
}

create_shared_volume() {
  if ! docker volume ls -q | grep -q "^$VOLUME_NAME$"; then
    echo "[+] Creating volume: $VOLUME_NAME"
    docker volume create "$VOLUME_NAME" > /dev/null
  else
    echo "[=] Volume already exists: $VOLUME_NAME"
  fi
}


start_dev_container() {
  local image="$1"
  local safe_name="${image//[\/:]/_}"
  local container_name="wsl2dev_$safe_name"

  if docker ps -a --format '{{.Names}}' | grep -q "^$container_name$"; then
    echo "[=] Container exists: $container_name - skipping"
    return
  fi

  docker pull "$image" > /dev/null || {
    echo "    [!] Failed to pull image $image"
    FAILED_CONTAINERS+=("$image")
    return
  }

  if $INTERACTIVE; then
    CMD="sh -c 'bash || sh'"
  else
    CMD="tail -f /dev/null"
  fi

  docker run -d \
    --name "$container_name" \
    --label "stack=wsl2-dev" \
    --label "source_image=$image" \
    -v "$VOLUME_NAME:/shared" \
    "$image" $CMD > /dev/null || {
      echo "    [!] Failed to start container $container_name"
      FAILED_CONTAINERS+=("$image")
      return
    }

  COMPOSE_SERVICES["$container_name"]="$image|$CMD"
  echo "[✓] Started: $container_name"
}

export_docker_compose() {
  echo "version: '3.8'" > docker-compose.yml
  echo "services:" >> docker-compose.yml

  for cname in "${!COMPOSE_SERVICES[@]}"; do
    IFS="|" read -r img cmd <<< "${COMPOSE_SERVICES[$cname]}"
    cat >> docker-compose.yml <<EOF
  $cname:
    image: $img
    container_name: $cname
    volumes:
      - $VOLUME_NAME:/shared
    command: $cmd
EOF
  done

  echo "volumes:" >> docker-compose.yml
  echo "  $VOLUME_NAME:" >> docker-compose.yml
  echo "[✓] Exported Docker Compose to docker-compose.yml"
}

# === Main Logic ===
check_docker_linux_mode
create_shared_volume

for img in "${DOCKER_IMAGES[@]}"; do
  start_dev_container "$img"
done

if $EXPORT_COMPOSE; then
  export_docker_compose
fi

if (( ${#FAILED_CONTAINERS[@]} )); then
  echo -e "\n[!] The following containers failed to start:"
  printf '%s\n' "${FAILED_CONTAINERS[@]}"
else
  echo -e "\n[✓] All containers started using volume: $VOLUME_NAME"
fi
