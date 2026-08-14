# MCP Source Model Contract

## Directory Structure

Each MCP server is an independent registry package:

```text
mcp-servers/<name>/
+-- MCP-SERVER.md
```

The first line of MCP-SERVER.md must be ---, and the frontmatter ends with another --- on its own line. The body is for detailed documentation only and does not participate in configuration generation.

## Common Fields

| Field | Required | Rules |
|---|---|---|
| name | yes | matches ^[a-z0-9]+(-[a-z0-9]+)*$, consistent with directory name |
| version | yes | MAJOR.MINOR.PATCH, no v prefix |
| description | yes | non-empty single-line or folded string |
| transport | yes | one of stdio, sse, streamable-http |
| targets | yes | non-empty, no duplicates, only claude/codex/gemini/opencode allowed |
| env-required | yes | YAML boolean; true when variables are used |
| env-vars | conditionally required | variable declaration list, target fixed to mcp |
| tags | no | string list for registry search |
| timeout | no | positive Go duration, e.g. 5s, 30s, 2m |
| platforms | no | stdio only, overrides command / args per GOOS |

Unknown fields must cause an error, preventing typos from being silently ignored.

## Transport Fields

| transport | required | optional | forbidden |
|---|---|---|---|
| stdio | command | args, cwd, env, timeout, platforms | url, headers |
| sse | url | headers, timeout | command, args, cwd, env |
| streamable-http | url | headers, timeout | command, args, cwd, env |

Field types:

- command, cwd, url, timeout are non-empty strings.
- args is a string list, preserving order.
- env and headers are string-to-string maps.
- url must use the http or https scheme.
- timeout expresses the timeout in the source model; the adapter converts it to the unit used by the target client. Do not pre-write it as seconds or milliseconds in the source file.

## STDIO Platform Override

A stdio MCP can declare platform differences:

```yaml
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
```

Semantics:

- The top-level command / args is the default, applying to Linux/macOS and also serving as fallback.
- platforms.<GOOS>.command / args overrides only the current platform; when not matched, the top-level config is used.
- Initially windows, linux, darwin are allowed; the registry does not require every platform to be declared.
- Only command and args are supported; do not declare shell, shell_args, cwd, env, or client-specific fields under platforms.
- args is replaced wholesale; args: [] means the current platform has no arguments, while omitting args falls back to the top-level.
- Do not auto-append .exe / .cmd, do not auto shell-wrap, do not do path conversion. Windows launch semantics must come from the MCP server distributor or be explicitly provided by the user.

## Parsing and Rendering Boundary

The correct order is:

```text
Parse YAML frontmatter
  -> construct transport discriminated union
  -> validate transport-specific fields
  -> select current platform command/args override for stdio
  -> parse and validate variables
  -> validate target capabilities
  -> generate adapter configs
```

Variables can only be substituted into allowed field string values after YAML is successfully parsed. Do not replace variables in raw YAML text; quotes, newlines, or special characters in variable values could break YAML structure.

When a single installation involves multiple clients, all adapter generation and validation must complete before committing writes atomically, to avoid partial success on some clients and failure on others.

## Body

The body must contain at least one heading and a purpose description, and may record installation prerequisites, auth sources, security notes, and server documentation entry points. The body:

- Does not participate in MCP configuration generation.
- Is not a supplementary source for missing frontmatter fields.
- Does not store tokens, passwords, or other real sensitive values.
- By default contains no TODOs, blank templates, or pending items.

## Version and Index

- New packages start at 1.0.0.
- Version must be bumped when the body, targets, transport config, variable declarations, or other effective metadata change.
- PATCH for minor fixes; MINOR for backward-compatible capability extensions; MAJOR for incompatible contract changes.
- After modification, run make index; do not manually edit mcp-servers/index.yaml.
- The index root key is mcp_servers; entries include name, version, description, optional tags, and path.
