---
name: project-coding-guideline
version: 1.0.2
description: >
  Default AI coding guideline template injected into project context files.
  Use when a project needs default AI coding behavior rules, or when user mentions default coding
  guidelines, AI coding behavior, project-level coding conventions, AGENTS.md default content,
  or CLAUDE.md default content.
targets:
  - CLAUDE.md
  - AGENTS.md
  - GEMINI.md
content: content.md
env-required: true
env-vars:
  - name: AIC_AVAILABLE_CLI_TOOLS
    description: List of local command-line tools declared as available by the project.
    required: false
    target: context
---

# Project-Level AI Coding Guideline

This context provides the default AI coding guideline template for aic-managed projects.
