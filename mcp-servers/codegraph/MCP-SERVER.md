---
name: codegraph
version: 1.1.0
description: CodeGraph repository analysis MCP server for project-scoped aic installation.
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
platforms:
  windows:
    command: codegraph.exe
    args:
      - serve
      - --mcp
env-required: false
tags:
  - code-analysis
  - repository
---
# CodeGraph MCP

[CodeGraph](https://github.com/colbymchenry/codegraph) builds a structured index for code repositories and provides code relationship and call path analysis capabilities through MCP.

This definition is added and managed by aic per project requirements. Do not run installation commands like `codegraph install --target=cursor,claude --yes` that directly modify global client config; this avoids injecting MCP servers into global config and reduces the cost of subsequent troubleshooting, updating, and uninstalling config.

Before use, ensure the current environment can execute the `codegraph init` command; the client connection is handled by aic generating project-level config and starting `codegraph serve --mcp`.

On Windows, this definition declares `codegraph.exe serve --mcp` as the stdio launch command. If your local installation provides a different command name or wrapper, explicitly adjust `platforms.windows.command` and `platforms.windows.args` in the registry source definition; aic does not auto-infer .exe, .cmd, or shell wrappers.
