---
name: aic-mcp-creator
version: 1.1.0
description: >
  Create, review, and incrementally update structured MCP server packages for the aic registry,
  generating and validating mcp-servers/<name>/MCP-SERVER.md. Handles stdio, SSE, and Streamable
  HTTP transports, environment variable placeholders, target client capabilities, version bumping,
  and mcp-servers/index.yaml.
  Use when user requests adding an MCP server definition, writing an MCP-SERVER.md, registering an
  MCP config into the registry, modifying an existing MCP source model, or checking MCP transport
  compatibility with Claude/Codex/Gemini/OpenCode.
  Do NOT use for implementing aic client parser/adapter, directly editing IDE native MCP config,
  starting an MCP server, or writing ordinary skills, contexts, or one-off MCP usage guides.
tags: [mcp, meta, registry-authoring]
env-required: false
---
# MCP Creator

Create a versionable MCP source definition. One MCP package has a single MCP-SERVER.md; the YAML frontmatter is the sole source of configuration, and the body contains only human-readable documentation.

## Before You Start

1. Confirm the repository contains mcp-servers/ or scripts/indexgen/indexgen.py; if neither exists, stop and explain that the current repository is not a supported registry layout.
2. Read the [source model contract](references/source-model.md). When variables are involved, also read [variable rules](references/variables.md); when choosing transport or targets, read [transport and client capabilities](references/transports.md). For complete samples, read [examples](references/examples.md).
3. Determine whether the task is first-time creation, incremental modification, or review. Only create or modify registry source definitions; do not implement aic parser, adapter, or client write logic.
4. Extract facts from the command, URL, headers, target clients, and description provided by the user. Never guess command arguments, auth headers, private addresses, or client support capabilities.

## Generate or Modify

1. Create mcp-servers/<name>/MCP-SERVER.md. The directory name, frontmatter name, and index entry name must all match and conform to ^[a-z0-9]+(-[a-z0-9]+)*$.
2. Declare exactly one transport: stdio, sse, or streamable-http. Strictly apply the required, allowed, and forbidden rules for the corresponding fields.
3. targets may only use claude, codex, gemini, opencode, with no duplicates. Before writing the file, reject unsupported combinations using the capability matrix; never auto-convert between SSE and Streamable HTTP.
4. Put all structured configuration in the frontmatter. The body should at minimum explain the purpose and necessary runtime prerequisites, but must not serve as adapter input or duplicate maintainable executable configuration.
5. When creating or modifying a stdio MCP, if the Windows launch command cannot be determined from user input or official distribution instructions, you must ask the user whether Windows adaptation is needed; if so, request explicit platforms.windows.command and platforms.windows.args. Never guess npx.cmd, .exe, cmd /c, PowerShell, or shell wrappers.
6. Use {{ aic.env.NAME }} for variables, allowed only in string values of command, args, cwd, env, url, headers, platforms.<goos>.command, and platforms.<goos>.args. Variables must be declared in env-vars, with names matching ^[A-Z][A-Z0-9_]*$, case-sensitive, no duplicates, and target fixed to mcp.
7. Variable substitution semantics are "parse YAML first, then replace string values in allowed fields". Never suggest or generate a flow that replaces raw YAML text before parsing.
8. New packages start at 1.0.0. When modifying the body or any frontmatter field of a published package, you must bump the version: PATCH for minor fixes, MINOR for backward-compatible capability extensions, MAJOR for incompatible contract changes.
9. The default deliverable must not contain TODOs, blank placeholders, or "pending user confirmation". When information is insufficient and would affect runtime configuration, ask the user first; for non-essential information, simply omit it. Placeholders are only allowed when the user explicitly requests scaffolding.
10. When modifying an existing package, make only local edits, preserving untouched fields and body. If the user explicitly requests direct modification, write to disk; otherwise, first explain which fields will change.

## Refresh and Validate

After completing the file, run:

```bash
make index
python3 skills/meta/aic-mcp-creator/scripts/validate_mcp_server.py . <name>
make validate
git diff -- mcp-servers/<name> mcp-servers/index.yaml skills/index.yaml
```

mcp-servers/index.yaml is a generated file; do not have users maintain it manually. The generator recursively scans mcp-servers/**/MCP-SERVER.md; entry versions come from the source file, and the registry version comes from the root VERSION.

Validation must cover: YAML has no duplicate keys; common fields are complete; transport fields are mutually exclusive; target capabilities match; timeout is a positive Go duration; variable declarations and references correspond one-to-one; the body does not participate in configuration; existing package versions have been bumped; the index version, description, and path match the source file.

## Delivery

State the MCP name, transport, targets, version change, modified files, and validation results. Explicitly state that the index has been refreshed by the generator. Do not claim that client native configs have been generated; that is the responsibility of the aic adapter.
