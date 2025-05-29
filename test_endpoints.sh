#!/bin/bash

echo "🔍 Testing LLM (Mistral) via HTTP..."
curl http://localhost:11434 -X POST -d '{"prompt": "Say hello from Mistral"}' -H "Content-Type: application/json"

echo "🧠 Testing Filesystem MCP..."
docker exec $(docker ps -qf "ancestor=mcp/filesystem") ls /rootfs

echo "🌐 Testing Fetch MCP..."
docker exec $(docker ps -qf "ancestor=mcp/fetch") curl https://example.com

echo "🗃️ Testing Git MCP..."
docker exec $(docker ps -qf "ancestor=mcp/git") ls /repo

echo "✅ All basic MCP tests executed."
