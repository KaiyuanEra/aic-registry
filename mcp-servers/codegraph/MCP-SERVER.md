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

[CodeGraph](https://github.com/colbymchenry/codegraph) 为代码仓库建立结构化索引，并通过 MCP 提供代码关系与调用路径分析能力。

本定义由 aic 按项目需求添加和管理。不需要执行 `codegraph install --target=cursor,claude --yes` 等直接修改全局客户端配置的安装命令，避免向全局配置注入 MCP server，并降低后续定位、更新和卸载配置的成本。

使用前应确保当前环境可以执行 `codegraph init` 命令；客户端连接时由 aic 生成项目级配置并启动 `codegraph serve --mcp`。

Windows 环境下，本定义声明了 `codegraph.exe serve --mcp` 作为 stdio 启动命令。若本机安装方式提供的是其他命令名或 wrapper，请在 registry 源定义中显式调整 `platforms.windows.command` 和 `platforms.windows.args`，aic 不会自动推断 `.exe`、`.cmd` 或 shell 包装。
