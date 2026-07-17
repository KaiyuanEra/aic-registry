---
name: project-coding-guideline
version: 1.0.1
description: Default AI coding guideline injected into project context files.
targets:
  - CLAUDE.md
  - AGENTS.md
  - Agents.md
content: content.md
env-required: true
env-vars:
  - name: AIC_AVAILABLE_CLI_TOOLS
    description: Local command-line tools available to the model.
    required: false
    target: context
---

# Project Coding Guideline

This context provides the default AI coding behavior guideline for aic-managed projects.
