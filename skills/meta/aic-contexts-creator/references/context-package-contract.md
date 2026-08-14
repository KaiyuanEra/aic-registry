
# Context Package Contract

## Directory Structure

Each context is an independent directory:

```text
contexts/<context-name>/
+-- CONTEXT.md
+-- content.md
```

Default names for stage contexts:

| Stage | context-name |
|---|---|
| Incubation and prototype | 01-incubation-prototype |
| Iteration and business evolution | 02-iteration-evolution |
| Maintenance and stable operation | 03-maintenance-stable |
| Refactor and evolution | 04-refactor-evolution |

Existing contexts keep their original names. Unless the user requests renaming, do not create a new directory as a substitute for a version bump.

## CONTEXT.md

The first line must be ---, with a closing --- on its own line:

```yaml
---
name: 02-iteration-evolution
version: 1.0.0
description: Project-level AI guidance for iteration and business evolution.
targets:
  - CLAUDE.md
  - AGENTS.md
  - GEMINI.md
content: content.md
env-required: false
---

# Iteration and Evolution Context

Project-level long-term memory for the iteration stage.
```

Hard requirements:

- name is non-empty, uses lowercase letters, digits, and hyphens, and matches the directory name exactly.
- version uses MAJOR.MINOR.PATCH, no v prefix.
- description is non-empty; scripts/indexgen/indexgen.py aggregates it into the index.
- targets contains at least one target file; preserve the user choice, do not add or remove without asking.
- content uses a relative filename within the package, default content.md; no absolute paths or ...
- env-required is a boolean only; when true, env-vars must not be empty.

Environment variable declaration example:

```yaml
env-required: true
env-vars:
  - name: AIC_AVAILABLE_CLI_TOOLS
    description: Local command-line tools available to the model.
    required: false
    target: context
```

See [variable declaration and reference](context-variables.md) for variable field meanings, placeholder syntax, and consistency rules. Whenever content.md uses variables, this declaration must be maintained alongside.

## Version Rules

Treat the context as a published artifact in the registry:

- New context: start at 1.0.0.
- Modifying body, targets, env var declarations, or other effective metadata: must bump version.
- Small-scope rule or fact fix: PATCH.
- New capability, section, or significant stage rule expansion: MINOR.
- Incompatible front matter or template contract: MAJOR.

Even a typo fix bumps at least PATCH, keeping artifact changes traceable against the index version. Record the old version before modifying; report old -> new explicitly on delivery.

## content.md

- Contains only the Markdown body for project-level long-term memory, without YAML front matter.
- Variables are defined and used per [variable declaration and reference](context-variables.md).
- No real tokens, passwords, keys, or private addresses.

## contexts/index.yaml

contexts/index.yaml is a generated file, not maintained manually by users. After completing context and version modifications, run:

```bash
make index
```

The existing scripts/indexgen/indexgen.py already:

1. Recursively scans contexts/**/CONTEXT.md;
2. Reads name, version, description, and optional tags;
3. Computes path from the context directory;
4. Writes results to contexts/index.yaml.

So no indexgen changes are needed for adding or modifying ordinary contexts. Only modify the generator when the registry needs to add new index fields, change multi-version retention policy, or adjust directory discovery rules.

Index entry example:

```yaml
registry_version: "v0.1.0"
contexts:
    - name: "02-iteration-evolution"
      version: "1.1.0"
      description: "Project-level AI guidance for iteration and business evolution."
      path: "contexts/02-iteration-evolution"
```

- registry_version comes from the repository root VERSION.
- Entry metadata comes from CONTEXT.md.
- After running the generator, verify that entry version and path match the context package.
- The current generator silently keeps the first scanned entry for duplicate (name, version) pairs; avoid duplicate combinations when creating packages.
