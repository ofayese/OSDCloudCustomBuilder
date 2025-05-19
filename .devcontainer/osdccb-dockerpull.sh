#!/bin/bash

# Define shared Docker volume
VOLUME_NAME="osdccb-dev-volume"

# Create volume if not exists
if ! docker volume inspect "$VOLUME_NAME" &>/dev/null; then
  echo "[+] Creating named volume: $VOLUME_NAME"
  docker volume create "$VOLUME_NAME"
else
  echo "[=] Named volume already exists: $VOLUME_NAME"
fi

# Define focused image list for PowerShell module dev + AI + MCP + Sourcegraph
docker_images=(
  # --- PowerShell Development ---
  mcr.microsoft.com/powershell:latest
  mcr.microsoft.com/powershell:preview
  mcr.microsoft.com/powershell:preview-7.6-ubuntu-24.04
  mcr.microsoft.com/azure-powershell:ubuntu-22.04
  mcr.microsoft.com/powershell/test-deps:debian-12
  mcr.microsoft.com/powershell/test-deps:lts-ubuntu-22.04
  mcr.microsoft.com/dotnet/framework/runtime:4.8.1
  mcr.microsoft.com/dotnet/framework/sdk:4.8.1

  # --- AI Tools ---
  ai/deepcoder-preview
  ai/llama3.2:latest
  ai/mistral:latest

  # --- MCP Tooling ---
  mcp/everything
  mcp/fetch
  mcp/filesystem
  mcp/git
  mcp/github
  mcp/gitlab
  mcp/memory
  mcp/postgres
  mcp/puppeteer
  mcp/sequentialthinking
  mcp/sentry
  mcp/sqlite
  mcp/time

  # --- Sourcegraph Stack ---
  sourcegraph/cody-gateway:insiders
  sourcegraph/executor:insiders
  sourcegraph/executor-vm:insiders
  sourcegraph/frontend:insiders
  sourcegraph/github-proxy:insiders
  sourcegraph/gitserver:insiders
  sourcegraph/indexed-searcher:insiders
  sourcegraph/initcontainer:insiders
  sourcegraph/node-exporter:insiders
  sourcegraph/opentelemetry-collector:insiders
  sourcegraph/redis-cache:insiders
  sourcegraph/redis_exporter:insiders
  sourcegraph/repo-updater:insiders
  sourcegraph/search-indexer:insiders
  sourcegraph/searcher:insiders
  sourcegraph/jaeger-agent:insiders
  sourcegraph/jaeger-all-in-one:insiders
  sourcegraph/sourcegraph-dev:insiders
  sourcegraph/sourcegraph-toolbox:insiders
  sourcegraph/symbols:insiders

  # --- Utility / Support ---
  containrrr/watchtower
  curlimages/curl
  postgres
  redis
  node
  python
)

# Launch each container with shared volume
for image in "${docker_images[@]}"; do
  echo -e "\n[>] Pulling image: $image"
  docker pull "$image"

  # Safe container name
  safe_name="${image//\//_}"
  safe_name="${safe_name//:/_}"
  container_name="dev_${safe_name}"

  # Skip existing containers
  if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
    echo "[=] Container already exists: $container_name — skipping"
    continue
  fi

  echo "[+] Running container: $container_name using volume: $VOLUME_NAME"

  docker run -d \
    --name "$container_name" \
    --label stack=dev \
    --label source_image="$image" \
    -v "$VOLUME_NAME:/shared" \
    "$image" sleep 3600
done

echo -e "\n✅ Dev containers launched with shared named volume: $VOLUME_NAME"
