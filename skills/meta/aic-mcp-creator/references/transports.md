# Transport and Client Capabilities

## Capability Matrix

Use the following registry capability boundaries when creating source definitions:

| transport | Claude | Codex | Gemini | OpenCode |
|---|---:|---:|---:|---:|
| stdio | supported | supported | supported | supported |
| sse | supported | not supported | supported | not supported |
| streamable-http | supported | supported | supported | supported |

When a target in targets does not support the current transport, error immediately. Do not remove the target and continue, and do not silently change sse to streamable-http.

## Adapter Semantics

The creator only defines the source model and does not directly generate the following files. These mappings are used to check whether source fields are sufficient, not to save client-specific configuration in the registry.

| Source model | Claude | Codex | Gemini | OpenCode |
|---|---|---|---|---|
| stdio transport | type: stdio | stdio server | stdio server | type: local |
| stdio command/args | command + args | native command and args | native command and args | merged into command array |
| streamable-http transport | type: http | server with url | httpUrl | type: remote |
| remote URL | url | url | httpUrl | url |
| remote headers | headers | http_headers | headers | headers |
| timeout | native field | seconds | milliseconds | milliseconds |

SSE retains independent transport semantics and can only target clients that explicitly support it in the capability matrix.

## Adapter Implementation Constraints

- The adapter only receives a normalized MCPServer that has passed source model and variable validation.
- Each adapter must explicitly reject fields it cannot express; it must not silently drop them.
- Config writes use incremental merging; they do not overwrite other servers not managed by aic.
- Multi-target writes generate all configs first, then commit atomically.
- Specific client config paths, merge algorithms, and version differences belong to the aic tool, not the registry creator skill.
