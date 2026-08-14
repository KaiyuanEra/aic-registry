# Context Anti-Patterns

| Anti-pattern | Risk | Fix |
|---|---|---|
| Modifying a published context without bumping version | Artifact changes cannot be identified from the index version | Bump at least PATCH on every modification |
| Adding front matter to content.md | Front matter gets injected verbatim into project memory files | Metadata goes only in CONTEXT.md |
| Manually editing contexts/index.yaml | Next index generation overwrites it | Run make index after modifying CONTEXT.md |
| Reminding users to manually edit contexts/index.yaml | Easily drifts from front matter and gets overwritten | Run make index and check the generated diff |
| Filling a general context with project-fact TODOs | Shifts information-gathering cost to users; deliverable is not directly usable | Omit unknown facts; rewrite as general, executable verification rules |
| Default delivery containing TODOs | Requires secondary editing after install, reducing efficiency | TODOs forbidden by default; only allowed in explicit scaffold mode |
| Guessing build/test commands | Agent executes non-existent or dangerous commands | Require verification from target project existing docs and config; report gaps when not found |
| Copying formatter/linter rules | Content bloat and easy drift | Only write intent and boundaries that tools cannot enforce |
| Pasting large code blocks or directory trees | Quickly becomes stale and crowds context | Reference stable paths and explain when to read them |
| Writing "this quarter" or "next sprint" | Creates stale info with no clear expiry point | Use verifiable state or removal conditions |
| Writing env vars as {{VAR}} | Does not conform to context template syntax | Use {{ aic.env.VAR }} and declare env-vars |
| Placeholder without a matching declaration | Context package variable contract is incomplete | Add the complete field in env-vars |
| Declaring a variable but not referencing it in body | Creates stale config with indeterminable purpose | Remove the declaration or add a real usage location |
| env-required: false but still declaring or referencing variables | Front matter self-contradiction | Change to true when variables exist; remove declarations and placeholders when none |
| Putting real sensitive values in templates | Sensitive values enter the version repository | Templates keep only declared placeholders |
| Rewriting the entire document for a modification | Loses conventions the user did not touch | Edit locally; show diff first |
| Context directory name not matching name | Lookup, install, and index semantics become confused | Keep both exactly consistent |
