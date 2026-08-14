---
name: aic-skill-creator
version: 2.2.0
description: >
  Author, design, and improve aic SKILL.md files.
  Use when creating a new skill from scratch, writing a SKILL.md, improving a skill description
  trigger quality, designing a skill directory structure, or when user mentions how to write a
  skill, description not triggering, which directory a skill belongs in, how to configure
  env-required, or how to add an adapter layer.
  Do NOT use for aic install/remove/sync commands, managing already-installed skills,
  or writing business code documentation unrelated to skills.
tags: [skill-authoring, meta, aic]
env-required: false
---

# aic Skill Creator

Authoring guide for aic skills. Follows the **TDD to Draft to Validate to Review to Ship** loop.

---

## Core Principles (read before you act)

1. **description is the only trigger mechanism** — Claude Code uses no regex or classifier; it aggregates every skill name + description into a meta-tool passed to the agent. Write a poor description and the skill will never trigger.
2. **Progressive Disclosure** — SKILL.md is a cheat sheet, not complete documentation. Push detail into references/ and load it on demand.
3. **aic constraints** — Every skill must have a version (semantic). When local configuration is needed, declare env-required: true and env-vars; never write real values.
4. **Variable names are a hard constraint** — Skills and Contexts share the rule ^[A-Z][A-Z0-9_]*$; names are case-sensitive and forbid lowercase letters, hyphens, dots, spaces, or leading digits/underscores; no duplicates within the same declaration.

---

## Workflow

### Step 0 — Write test cases first (TDD)

Before writing SKILL.md, list the trigger scenarios:

```
Should trigger (positive examples)
- "Help me write a skill for Kafka consumption"
- "I need to create a SKILL.md for database operations"
- "How can I improve this skill description?"

Should NOT trigger (negative examples)
- "aic install kafka-ops"
- "List installed skills"
- "Help me write a Kafka consumer" (not a skill-authoring task)
```

Let the test cases drive the description, not the other way around.

---

### Step 1 — Create the directory structure

```bash
# Create under skills/ (common/ or domain/ depending on business relevance)
mkdir -p skills/common/<skill-name>/{references,scripts,assets}
cp assets/SKILL.template.md skills/common/<skill-name>/SKILL.md
```

The directory name must **exactly match** the frontmatter name field (lowercase kebab-case).

---

### Step 2 — Fill in the frontmatter

```yaml
---
name: <skill-name>           # must match the directory name exactly
version: 1.0.0               # required, semantic version
description: >               # see Step 3
  ...
tags: [<tag1>, <tag2>]       # helps filtering in aic list
env-required: false          # change to true if local variables need injecting
# When env-required: true you must also add:
# env-vars:
#   - name: DB_HOST
#     description: Database host
#     required: true
#     target: skill
---
```

**Variable names must match ^[A-Z][A-Z0-9_]*$.** Valid: API_KEY, API_BASE_URL, AIC_AVAILABLE_CLI_TOOLS, MODEL_V2_ENDPOINT. Invalid: api_key, 2FA_TOKEN, API-KEY, API.KEY, _API_KEY. No duplicates within the same env-vars; names are case-sensitive. See [aic-specific spec](references/skm-spec.md) for full rules.

---

### Step 3 — Write the description using the formula

Apply this formula, then validate against the Step 0 test cases:

```
[Verb phrase describing the core function].
Use when [positive scenario 1], [positive scenario 2], or when user mentions [keyword list].
Do NOT use for [exclusion scenario] or [easily confused adjacent scenario].
```

Run the scoring script to check quality:

```bash
scripts/description-score.sh skills/<category>/<skill-name>/SKILL.md
```

If the score is < 60, rewrite the description. See [description pattern library](references/description-patterns.md).

---

### Step 4 — Write the body

Body structure (reference, not mandatory):

```markdown
## When to use
When to use / when not to use

## Prerequisites / Core objects
Key files, config entry points, important concepts

## Workflow
1. Step one -> output
2. Step two -> output

## Common edge cases
Pitfalls and how to handle them

## Examples
Concrete input / output
```

**Length control:** Body < 500 lines (~5000 tokens). Move longer content into references/.

#### env-required skill body conventions

When env-required: true, do not write real values or rendered copies into SKILL.md.

**Key constraints:**

- Variables declared in env-vars must be explicitly referenced in the body or script docs for their **purpose and missing-value handling**.
- Never require the agent to rely on memorized values, values from a previous project, or guesses.
- Real IPs, domains, passwords, or tokens must **never appear** in any file — including references/ and scripts/.

```yaml
# Correct: state the purpose, do not write real values
DB_HOST is the database connection entry point; if missing, stop and prompt the user to fill it in

# Wrong: hardcoded real values
Host: 10.0.1.100
```

---

### Step 5 — Structural validation

```bash
scripts/validate.sh skills/<category>/<skill-name>/SKILL.md
```

All checks must pass before review. See [anti-patterns doc](references/anti-patterns.md) for common errors.

---

### Step 6 — Three-tool compatibility check

| Scenario | Handling |
|----------|----------|
| Skill behaves identically across all three tools | Only the .agents/skills/ symlink is needed; no adapter layer |
| Claude Code needs allowed-tools or other proprietary fields | Add them in adapters/claude/SKILL.md |
| A tool has special UI metadata needs | See [compatibility matrix](references/compatibility-matrix.md) |

```bash
# Confirm all three tools can read it (run inside an aic-initialized project)
scripts/self-test.sh <skill-name>
```

---

### Step 7 — Refresh and Validate

After completing the file, run:

```bash
make index
scripts/validate.sh skills/<category>/<skill-name>/SKILL.md
make validate
git diff -- skills/<category>/<skill-name>/ skills/index.yaml
```

`skills/index.yaml` is a generated file; do not have users maintain it manually. The generator recursively scans `skills/**/SKILL.md`; entry versions come from the source file, and the registry version comes from the root `VERSION`.

`validate.sh` does single-file regex checks (field existence, name matches directory, version is semver, env-vars names are valid), but `indexgen.py`'s `parse_frontmatter` actually parses the YAML frontmatter (including `>`/`|` block scalars) and catches problems the former misses: leading blank lines making the first line non-`---`, block scalar indentation errors or empty content, missing name/version/description, and cross-file name+version duplicates.

Validation must cover: frontmatter starts with `---` and has a terminator; name matches the directory name; version is semver; description is non-empty; env-required and env-vars declarations match; body is < 500 lines; indexgen parses all SKILL.md files without error; the index version, description, and path match the source file.

---

### Step 8 — Delivery

```bash
# Ensure version is set in SKILL.md frontmatter
# CI will automatically update skills/index.yaml
git add skills/<category>/<skill-name>/
git commit -m "feat(skill): add <skill-name> v1.0.0"
# Push and create an MR on GitLab, targeting the dev branch
```

State the skill name, version change, modified files, and validation results. Explicitly state that the index has been refreshed by the generator. After the MR merges, engineers can install the skill via `aic install <skill-name>`.
---

## Quick Reference

| I need to... | Look here |
|-----------|--------|
| How to write a description that triggers | [description pattern library](references/description-patterns.md) |
| What common mistakes am I making | [anti-patterns doc](references/anti-patterns.md) |
| env-required / version / adapter layer spec | [aic-specific spec](references/skm-spec.md) |
| Three-tool paths and compatibility | [compatibility matrix](references/compatibility-matrix.md) |
| Start from a blank template | [assets/SKILL.template.md](assets/SKILL.template.md) |
