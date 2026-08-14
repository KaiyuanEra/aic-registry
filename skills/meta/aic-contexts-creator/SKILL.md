---
name: aic-contexts-creator
version: 1.5.0
description: >
  Create, migrate, and incrementally update development-stage project-level long-term memory
  context packages for the context registry, producing and validating contexts/<context-name>/CONTEXT.md
  and content.md, bumping versions and syncing contexts/index.yaml.
  Use when user requests writing or standardizing CLAUDE.md, AGENTS.md, Agents.md, project memory files,
  or project context, migrating old memory into a registry context, switching between
  incubation/iteration/maintenance/refactor stage guidelines, or creating projects similar to
  contexts/project-coding-guideline.
  Do NOT use for ordinary business documentation, one-off session prompts, skill authoring,
  or modifying tool implementations outside the context registry.
tags: [context-authoring, meta, project-memory]
env-required: false
---

# Contexts Creator

Organize user-provided facts into registry context packages. Each stage can exist as an independent, versionable context directory.

## Before You Start

1. Confirm the current repository contains contexts/ and scripts/indexgen/indexgen.py. If missing, stop and explain that the current repository is not a supported context registry layout.
2. Read the [context package contract](references/context-package-contract.md). When variables are involved, also read [variable declaration and reference](references/context-variables.md); for body structure, read the [standard template](references/context-template.md); when reviewing or migrating old files, also read [anti-patterns](references/anti-patterns.md).
3. Determine the deliverable type: a general reusable context, a project-specific context, or a fill-in scaffold explicitly requested by the user; also determine whether this is first-time creation, migration, incremental modification, or stage switching.
4. Only read descriptions, documents, and old memory files explicitly provided by the user. Unless the user requests otherwise, do not auto-scan the codebase to infer tech stack, commands, or directory structure.

## Collect Facts

Extract and record sources from existing materials:

- Current stage: incubation, iteration, maintenance, or refactor
- Project positioning, users, and scope boundaries
- Tech stack, architecture boundaries, and real paths
- Confirmed build, test, lint, and startup commands
- Conventions that linters cannot enforce, high-risk operations, and completion criteria
- External documentation to reference
- Whether environment variable template placeholders are needed

General reusable contexts only distill cross-project stage rules and do not require project-specific tech stack, commands, or directory information. Project-specific contexts only ask about missing facts that would change the deliverable, and resolve necessary issues before generation. Never guess commands, paths, modules, dependency versions, or tool support.

**The default deliverable must not contain TODOs, blank placeholders, or "pending user confirmation".** When non-essential facts are missing, omit them and retain directly executable general rules. Placeholders are only allowed when the user explicitly requests a template or scaffold.

## Choose Stage Focus

Keep the same seven-section skeleton; only change content weighting:

| Stage | Focus | Constraints |
|---|---|---|
| incubation | project positioning, common commands | stay lightweight, clarify prototype boundaries, avoid prematurely freezing production rules |
| iteration | code conventions, validation flow, prohibitions | control bloat, move detail to stable external docs |
| maintenance | high-risk operations, validation flow | highlight release, secret, and migration boundaries; remove exploration-phase legacy notes |
| refactor | architecture, external docs | write clear old/new boundaries; temporary rules must carry verifiable expiry conditions |

When no name is specified, use 01-incubation-prototype, 02-iteration-evolution, 03-maintenance-stable, 04-refactor-evolution by stage. Only generate the stage the user currently needs; do not create four empty packages at once for completeness.

## Generate or Modify

1. Create CONTEXT.md and content.md in contexts/<context-name>/; CONTEXT.md.name must match the directory name, and content.md must not have YAML front matter.
2. Use the standard seven-section skeleton, keeping it under 200 lines where possible; replace pasted code with a one-sentence note referencing confirmed real paths. When no real path exists, write general document discovery and verification rules; do not generate path placeholders.
3. Only write rules that linters/formatters cannot automatically guarantee; explain the reason for non-obvious rules.
4. Avoid easily-expired time descriptions like "this quarter" or "next sprint".
5. When variables are needed, maintain both CONTEXT.md.env-vars and content.md placeholders per [variable declaration and reference](references/context-variables.md). Do not use undeclared variables, do not leave unused declarations, and do not write real secrets or sensitive values.
   **Variable names must match ^[A-Z][A-Z0-9_]*$, are case-sensitive, and must not be duplicated within the same declaration.**
6. Create or update CONTEXT.md per the [context package contract](references/context-package-contract.md). New packages start at 1.0.0; any modification to a published context must bump the version, defaulting to at least PATCH.
7. When modifying an existing package, make only local edits, preserving untouched content. Show the diff and wait for user confirmation before writing to disk; if the user explicitly requested direct modification, treat it as confirmed.
8. Run make index to regenerate contexts/index.yaml; do not have users maintain generated files manually. The generator already recursively scans contexts/**/CONTEXT.md; no need to modify scripts/indexgen/indexgen.py for new contexts. The registry version comes from the root VERSION; context entry versions come from CONTEXT.md.

Version selection: typo, fact fix, or rule change that does not alter structure -> PATCH; new section capability or significant rule expansion -> MINOR; incompatible context contract change -> MAJOR. Do not modify only content.md while keeping the old version.

## Validate and Deliver

Run:

```bash
make index
skills/meta/contexts-creator/scripts/validate-context.sh . <context-name>
make validate
git diff -- contexts/<context-name> contexts/index.yaml
```

Check each item: seven-section skeleton exists; default body contains no TODOs or blank placeholders; facts have sources; body has no front matter; variable declarations and placeholders are consistent; contexts/index.yaml version, description, and path match CONTEXT.md; diff contains no unrelated changes.

When delivering, state the selected stage, context name, modified files, old-to-new version change, and validation results. Explicitly tell the user that contexts/index.yaml has been refreshed by the generator and needs no manual maintenance. If the user explicitly requested scaffolding, separately summarize the retained placeholders.
