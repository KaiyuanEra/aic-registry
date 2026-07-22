---
name: searxng-http
version: 1.0.0
description: 基于 SearXNG 的网络搜索 MCP 服务，通过 Streamable HTTP 提供连接。
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
    description: 目标客户端可访问且以 /mcp 结尾的 Streamable HTTP MCP 服务地址。
    required: true
    target: mcp
tags:
  - search
  - searxng
  - streamable-http
---
# SearXNG Streamable HTTP MCP

[mcp-searxng](https://github.com/ihor-sokoliuk/mcp-searxng) 为 AI 客户端提供网页搜索和网页内容读取能力，搜索请求由一个或多个 SearXNG 实例处理。

请使用上游 Docker 镜像部署服务。传入容器的 `SEARXNG_URL` 必须是服务实际访问的 SearXNG 实例地址。

```bash
docker run --rm -p 3000:3000 \
  -e MCP_HTTP_PORT=3000 \
  -e MCP_HTTP_HOST=0.0.0.0 \
  -e SEARXNG_URL \
  isokoliuk/mcp-searxng:latest
```

容器通过 `http://localhost:3000/mcp` 暴露 Streamable HTTP MCP 端点，并通过 `http://localhost:3000/health` 提供健康检查。请将 aic MCP 变量 `SEARXNG_MCP_URL` 设置为目标客户端可以访问的 `/mcp` 地址。该变量与容器内的 `SEARXNG_URL` 有意区分：前者是 MCP 服务地址，后者是后端 SearXNG 服务地址。

服务默认只绑定本机地址；上面的 Docker 命令将服务绑定到容器的所有网络接口。如果需要暴露到不受信任的网络，请先按照上游文档启用 HTTP 加固和身份认证配置。
