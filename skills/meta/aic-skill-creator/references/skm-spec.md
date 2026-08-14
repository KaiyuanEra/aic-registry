# aic-Specific Spec

> This document is the aic extension layer for the SKILL.md standard spec.
> Standard spec (name / description / Progressive Disclosure) is in the main SKILL.md body.

---

## 1. Version Field (required)

aic requires every skill to have a version field conforming to semantic versioning (SemVer):

```yaml
---
name: database-ops
version: 1.2.0        # required, format: MAJOR.MINOR.PATCH
---
```

**Version and Git tag correspondence:**

- aic install database-ops reads the latest version from skills/index.yaml
- aic install database-ops@1.2.0 checks out the corresponding Git tag skills/database-ops@1.2.0
- **Skills without a version field or without a corresponding Git tag are refused installation**

**Version bump rules:**

| Change type | Version change | Example |
|----------|----------|------|
| Fix description false-trigger, typo | PATCH | 1.0.0 -> 1.0.1 |
| Add content, expand use scenarios | MINOR | 1.0.0 -> 1.1.0 |
| Rewrite description, refactor structure, breaking change | MAJOR | 1.0.0 -> 2.0.0 |

---

## 2. env-required Design

### When to use

Set env-required: true only when the skill body needs to reference local sensitive information (database connections, API keys, internal service addresses, etc.).

### Complete frontmatter example

```yaml
---
name: database-ops-with-creds
version: 1.0.0
description: >
  Run database migrations, query optimization, and connection configuration.
  Use when working with MySQL/PostgreSQL operations, schema migrations, or query tuning.
  Do NOT use for Redis, MongoDB, or non-relational databases.
tags: [database, backend]
env-required: true
env-vars:
  - name: DB_HOST
    description: Database host address
    required: true
    target: skill
  - name: DB_USER
    description: Database username
    required: true
    default: ""
    target: skill
  - name: DB_PASSWORD
    description: Database password
    required: true
    target: skill
---
```

### Variable reading convention

Do not write real values in the body, and do not rely on pre-rendered copies. env-required skills should clearly state variable purpose and missing-value handling in the body:

```markdown
If DB_HOST / DB_USER is missing, stop and prompt the user to run aic env add or aic env edit to fill them in.
```

> **Recommended practice:**
> - State variable purpose, missing-value handling, and the no-guessing constraint in SKILL.md
> - Never write real IPs, domains, tokens, or passwords in any file — including references/ and scripts/

### env-vars declaration usage requirements

Variables declared in env-vars must be explicitly referenced in the SKILL.md body, reference, or script docs for their purpose, read source, and missing-value handling.

### Variable name hard rules

Skills and Contexts use the exact same variable name rule:

```text
^[A-Z][A-Z0-9_]*$
```

- Must start with an uppercase letter.
- Subsequent characters can only be uppercase letters, digits, and underscores.
- Case-sensitive.
- No lowercase letters, hyphens, dots, or spaces.
- No leading digits or underscores.
- No duplicates within the same env-vars declaration.

Valid examples:

```text
API_KEY
API_BASE_URL
AIC_AVAILABLE_CLI_TOOLS
MODEL_V2_ENDPOINT
```

Invalid examples:

```text
api_key
2FA_TOKEN
API-KEY
API.KEY
_API_KEY
```

### env-required skill testing notes

scripts/validate.sh should check at minimum:
- When env-required: true, env-vars must not be empty
- All variable names match ^[A-Z][A-Z0-9_]*$ and have no duplicate declarations
- Missing variables require stopping and prompting the user to fill them in
- No .md file should contain suspected real IPs, passwords, or hardcoded token strings

---

## 3. Adapter Layer

### When an adapter layer is needed

When a skill needs different content for different AI tools, create tool-specific versions in the adapters/ directory:

```
database-ops/
+-- SKILL.md                    <- universal version for all three tools (in .agents/skills/)
+-- adapters/
    +-- claude/
    |   +-- SKILL.md            <- Claude Code specific version (in .claude/skills/)
    +-- codex/
        +-- SKILL.md            <- Codex specific version
```

### Common adapter layer use cases

| Scenario | Adapter layer content |
|------|-----------|
| Claude Code needs allowed-tools control | Add allowed-tools: [Bash, Read] to adapters/claude/SKILL.md frontmatter |
| Codex needs agents/openai.yaml metadata | Add agents/openai.yaml in adapters/codex/ |
| A tool has different workflow steps | Adapter layer overrides that part of the body |

### Adapter layer frontmatter inheritance rules

Adapter layer SKILL.md should keep the same name and version as the main SKILL.md, modifying only the differences. aic does not do field merging; adapter layer files are complete standalone files.

### When an adapter layer is NOT needed

Most skills do not need an adapter layer. If the difference is only wording, write it in the main SKILL.md. Adapter layers add maintenance cost; use them only when there is a clear tool-specific need.

---

## 4. skills/index.yaml Maintenance

index.yaml is maintained automatically by CI and **does not need manual editing**. Conditions that trigger CI updates:

- A new skills/<category>/<skill-name>/SKILL.md is pushed to the dev branch
- A Git tag in the format skills/<skill-name>@<version> is created

To publish a new version:
1. Confirm version is updated in SKILL.md
2. Create the corresponding tag: git tag skills/database-ops@1.3.0
3. Push the tag: git push origin skills/database-ops@1.3.0
4. CI automatically updates index.yaml

---

## 5. Skill Declaration in .aicrc

After an engineer installs a skill in their project, .aicrc automatically records:

```toml
[[skills]]
name         = "database-ops"
version      = "1.2.0"
env_required = true    # reminds collaborators this skill needs ~/.aic-env config
```

Skill authors do not need to worry about .aicrc; it is maintained automatically by aic. However, the skill README or SKILL.md should explain how to configure env-required skill variables, to help new team members onboard.
