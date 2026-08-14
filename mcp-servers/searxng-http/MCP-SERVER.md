---
name: searxng-http
version: 1.0.0
description: SearXNG-based web search MCP service, providing connectivity via Streamable HTTP.
transport: streamable-http
targets:
  - claude
  - codex
  - gemini
  - opencode
url: "{{ aic.env.SEARXNG_MCP_URL }}"
env-required: true
env-vars:
  - name: SEARXNG_MCP_URL
    description: Streamable HTTP MCP service URL accessible by the target client, ending with /mcp.
    required: true
    target: mcp
tags:
  - search
  - searxng
  - streamable-http
---
# SearXNG Streamable HTTP MCP

[mcp-searxng](https://github.com/ihor-sokoliuk/mcp-searxng) provides web search and web content reading capabilities for AI clients. Search requests are processed by one or more SearXNG instances.

Use the upstream Docker image to deploy the service. The `SEARXNG_URL` passed to the container must be the actual SearXNG instance address accessible by the service.

```bash
docker run --rm -p 3000:3000 \
  -e MCP_HTTP_PORT=3000 \
  -e MCP_HTTP_HOST=0.0.0.0 \
  -e SEARXNG_URL \
  isokoliuk/mcp-searxng:latest
```

The container exposes a Streamable HTTP MCP endpoint at `http://localhost:3000/mcp` and a health check at `http://localhost:3000/health`. Set the aic MCP variable `SEARXNG_MCP_URL` to the `/mcp` address accessible by the target client. This variable is intentionally distinct from the container `SEARXNG_URL`: the former is the MCP service address, the latter is the backend SearXNG service address.

The service binds to localhost by default; the Docker command above binds the service to all network interfaces of the container. If you need to expose it to untrusted networks, first enable HTTP hardening and authentication configuration per the upstream documentation.
