# ---- Base Image Setup ----
ARG BASE_IMAGE
FROM ${BASE_IMAGE} as base

# ---- MCP Images Stages ----
FROM mcp/everything as everything
FROM mcp/fetch as fetch
FROM mcp/filesystem as filesystem
FROM mcp/git as git-tools
FROM mcp/github as github-tools
FROM mcp/gitlab as gitlab-tools
FROM mcp/memory as memory-tools
FROM mcp/postgres as postgres-tools
FROM mcp/puppeteer as puppeteer-tools
FROM mcp/sequentialthinking as sequential-thinking

# ---- Sourcegraph Images Stages ----
FROM sourcegraph/opentelemetry-collector:insiders as otel-collector
FROM sourcegraph/frontend:insiders as frontend-tools
FROM sourcegraph/indexed-searcher:insiders as indexed-searcher
FROM sourcegraph/gitserver:insiders as gitserver
FROM sourcegraph/github-proxy:insiders as github-proxy
FROM sourcegraph/jaeger-agent:insiders as jaeger-agent
FROM sourcegraph/symbols:insiders as symbols
FROM sourcegraph/redis_exporter:insiders as redis-exporter
FROM sourcegraph/repo-updater:insiders as repo-updater
FROM sourcegraph/initcontainer:insiders as initcontainer
FROM sourcegraph/sourcegraph-dev:insiders as sourcegraph-dev
FROM sourcegraph/redis-cache:insiders as redis-cache
FROM sourcegraph/searcher:insiders as searcher
FROM sourcegraph/executor:insiders as executor
FROM sourcegraph/jaeger-all-in-one:insiders as jaeger-all-in-one
FROM sourcegraph/sourcegraph-toolbox:insiders as toolbox
FROM sourcegraph/cody-gateway:insiders as cody-gateway
FROM sourcegraph/executor-vm:insiders as executor-vm
FROM sourcegraph/grafana:insiders as grafana
FROM sourcegraph/node-exporter:insiders as node-exporter
FROM sourcegraph/search-indexer:insiders as search-indexer

# ---- Final Stage ----
FROM base

# ---- MCP Copies ----
COPY --from=everything /app /mcp/everything
COPY --from=fetch /app /mcp/fetch
COPY --from=filesystem /app /mcp/filesystem
COPY --from=git-tools /usr/bin/git /usr/bin/git
COPY --from=github-tools /tools/github /tools/github
COPY --from=gitlab-tools /tools/gitlab /tools/gitlab
COPY --from=memory-tools /memory /memory
COPY --from=postgres-tools /var/lib/postgresql /var/lib/postgresql
COPY --from=puppeteer-tools /puppeteer /puppeteer
COPY --from=sequential-thinking /thinking /thinking

# ---- Sourcegraph Copies ----
COPY --from=otel-collector /otel /otel
COPY --from=frontend-tools /usr/local/bin/frontend-tool /usr/local/bin/frontend-tool
COPY --from=indexed-searcher /searcher /searcher
COPY --from=gitserver /gitserver /gitserver
COPY --from=github-proxy /github-proxy /github-proxy
COPY --from=jaeger-agent /jaeger-agent /jaeger-agent
COPY --from=symbols /symbols /symbols
COPY --from=redis-exporter /redis-exporter /redis-exporter
COPY --from=repo-updater /repo-updater /repo-updater
COPY --from=initcontainer /initcontainer /initcontainer
COPY --from=sourcegraph-dev /app /sourcegraph-dev
COPY --from=redis-cache /redis-cache /redis-cache
COPY --from=searcher /searcher-service /searcher-service
COPY --from=executor /executor /executor
COPY --from=jaeger-all-in-one /jaeger /jaeger
COPY --from=toolbox /toolbox /toolbox
COPY --from=cody-gateway /gateway /gateway
COPY --from=executor-vm /executor-vm /executor-vm
COPY --from=grafana /grafana /grafana
COPY --from=node-exporter /node-exporter /node-exporter
COPY --from=search-indexer /search-indexer /search-indexer

# ---- Development Environment Setup ----

RUN apt-get update && apt-get install -y wget curl unzip git jq gnupg lsb-release && rm -rf /var/lib/apt/lists/*

RUN pwsh -Command @'
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted;
    Install-Module -Name PSScriptAnalyzer -Force -Scope AllUsers;
    Install-Module -Name PowerShellProTools -Force -Scope AllUsers;
    Install-Module -Name OSD -Force -Scope AllUsers;
    Install-Module -Name PSReadLine -Force -Scope AllUsers;
    Install-Module -Name Terminal-Icons -Force -Scope AllUsers;
    Install-Module -Name Az -Force -Scope AllUsers;
    Install-Module -Name Evergreen -Force -Scope AllUsers;
    Install-Module -Name EGH -Force -Scope AllUsers;
'@

RUN mkdir -p /opt/winadk &&     curl -LO https://go.microsoft.com/fwlink/?linkid=2166019 &&     curl -LO https://go.microsoft.com/fwlink/?linkid=2166224 || true

CMD [ "pwsh" ]