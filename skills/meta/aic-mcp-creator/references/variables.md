
# MCP Variable Declaration and Reference

## Declaration Format

Variables are declared in the env-vars section of the MCP-SERVER.md frontmatter:

```yaml
env-required: true
env-vars:
  - name: MCP_TOKEN
    description: Access token sent in the MCP Authorization header.
    required: true
    target: mcp
```

Each variable item supports:

| Field | Required | Rules |
|---|---|---|
| name | yes | matches ^[A-Z][A-Z0-9_]*$, unique within the package |
| description | yes | explains the purpose, contains no real values |
| required | yes | YAML boolean |
| target | yes | fixed to mcp |
| default | no | only stable, non-sensitive string default values allowed |

Variable names are case-sensitive. Valid examples: API_KEY, API_BASE_URL, AIC_AVAILABLE_CLI_TOOLS, MODEL_V2_ENDPOINT; api_key, 2FA_TOKEN, API-KEY, API.KEY, _API_KEY are all invalid.

## Reference Format

The standard placeholder is:

```text
{{ aic.env.MCP_TOKEN }}
```

It may only be referenced in the string values of the following fields:

- command
- elements of args
- cwd
- values of env
- url
- values of headers
- platforms.<goos>.command
- elements of platforms.<goos>.args

Referencing is not allowed in key names, name, version, description, transport, targets, timeout, variable declarations, or Markdown body text.

## Consistency Rules

1. Each placeholder must have exactly one declaration with the same name.
2. Each declaration must be referenced at least once in an allowed field.
3. When declarations or placeholders exist, env-required must be true.
4. When env-required: true, env-vars must be non-empty.
5. When env-required: false, no env-vars or placeholders may appear.
6. Variables are resolved first from the project env, then fall back to the global env; the registry does not store resolved values.
7. No client configuration may be written before variable resolution is complete.
8. When required: true and the value is missing, stop the entire multi-target installation; do not leave partial writes.
9. default must not store tokens, passwords, private addresses, or environment-specific values.
