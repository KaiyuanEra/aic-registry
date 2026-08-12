---
name: project-coding-guideline
version: 1.0.2
description: 默认注入到项目 context 文件的 AI 编码行为准则中文模板。Use when 项目需要默认的 AI 编码行为规范，或用户提及 默认编码准则、AI 编码行为、项目级编码规范、AGENTS.md 默认内容、CLAUDE.md 默认内容。
targets:
  - CLAUDE.md
  - AGENTS.md
  - GEMINI.md
content: content.md
env-required: true
env-vars:
  - name: AIC_AVAILABLE_CLI_TOOLS
    description: 项目声明可用的本地命令行工具清单。
    required: false
    target: context
---

# 项目级 AI 编码行为准则

本 context 提供 aic 管理项目的默认 AI 编码行为准则中文模板。
