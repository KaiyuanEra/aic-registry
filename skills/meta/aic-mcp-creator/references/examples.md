# MCP-SERVER.md 示例

## STDIO

```markdown
---
name: codegraph
version: 1.0.0
description: CodeGraph repository analysis MCP server.
transport: stdio
targets:
  - claude
  - codex
  - gemini
  - opencode
command: codegraph
args:
  - serve
  - --mcp
env-required: false
---

# CodeGraph MCP

Provides repository graph analysis through MCP.
```

## SSE

```markdown
---
name: legacy-events
version: 1.0.0
description: Legacy SSE MCP endpoint.
transport: sse
targets:
  - claude
  - gemini
url: https://mcp.example.com/sse
headers:
  Authorization: "Bearer {{ aic.env.MCP_TOKEN }}"
timeout: 30s
env-required: true
env-vars:
  - name: MCP_TOKEN
    description: Access token sent in the MCP Authorization header.
    required: true
    target: mcp
---

# Legacy Events MCP

Connects supported clients to the legacy event stream.
```

## Streamable HTTP

```markdown
---
name: issue-tracker
version: 2.1.0
description: Team issue tracker MCP server.
transport: streamable-http
targets:
  - claude
  - codex
  - gemini
  - opencode
url: https://mcp.example.com/mcp
headers:
  Authorization: "Bearer {{ aic.env.MCP_TOKEN }}"
timeout: 30s
env-required: true
env-vars:
  - name: MCP_TOKEN
    description: Access token sent in the MCP Authorization header.
    required: true
    target: mcp
---

# Issue Tracker MCP

Provides issue lookup and update tools to supported clients.
```

这些示例描述源模型，不表示 creator 已经写入任何客户端配置。
