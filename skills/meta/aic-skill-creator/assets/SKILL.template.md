---
# SKILL.md Standard Template
# Usage:
#   1. Copy this file to skills/<category>/<skill-name>/SKILL.md
#   2. Directory name must match the name field exactly (lowercase kebab-case)
#   3. Remove all comment lines (starting with #) before submitting MR
#   4. Run validate.sh and description-score.sh to verify
#
# Category reference:
#   skills/common/   -> general skills, business-agnostic (git, docker, code-review, etc.)
#   skills/domain/   -> business domain skills (database-ops, backend-api, frontend-build, etc.)

name: <skill-name>           # must match directory name exactly, lowercase kebab-case
version: 1.0.0               # required, semantic version; fix -> patch, add -> minor, refactor -> major
description: >
  # Must be written in English: cover technical terms and natural-language keywords
  # Formula: [English functional summary]. Use when [English technical scenario],
  #          or when user mentions [natural-language keyword], [command].
  #          Do NOT use for [exclusion scenario].
  # Example:
  #   Run database migrations, optimize slow queries, and manage connection configuration.
  #   Use when running schema migrations or tuning query performance,
  #   or when user mentions database migration, slow query, connection issue, or db migrate.
  #   Do NOT use for Redis/MongoDB or application-layer ORM code.
  <fill in description here>
tags: [<tag1>, <tag2>]       # for aic list filtering, 2 to 4 tags

# -- env-required (enable as needed) ----------------------
# If the skill does not need local variable injection, remove all env-related lines below
env-required: false

# When env-required: true, uncomment and fill in:
# Variable names must match ^[A-Z][A-Z0-9_]*$, case-sensitive, no duplicates within env-vars
# env-required: true
# env-vars:
#   - name: DB_HOST
#     description: Database host address
#     required: true
#     target: skill
#   - name: DB_USER
#     description: Database username
#     required: true
#     default: ""
#     target: skill
#   - name: DB_PASSWORD
#     description: Database password
#     required: true
#     target: skill
---

# <Skill Name>

<!-- One sentence describing the core value of this skill, for the aic list detail panel -->

---

## When to use

**Use for:**
- <scenario one>
- <scenario two>

**Do NOT use for:**
- <exclusion scenario one> (should use <other-skill> skill)

---

## Prerequisites

<!-- List key files, config entry points, or core concepts the agent needs to know -->
<!-- Keep to 5 to 10 items, stay concise -->

- <key file or config>: <path or description>
- <core concept>: <one-sentence explanation>

---

## Workflow

<!-- Describe with imperative steps, each step states input and output -->

1. **<step one>** — <operation description>
   ```bash
   <example command>
   ```
   Output: <output description>

2. **<step two>** — <operation description>

3. **<step three>** — <operation description>

---

## Common edge cases

<!-- List pitfalls and how to handle them -->

| Case | Handling |
|------|----------|
| <edge case one> | <handling> |
| <edge case two> | <handling> |

---

## Examples

<!-- Concrete input/output examples are more effective than abstract descriptions -->

**Input:** <user request description>

**Actions:**
```bash
<specific commands or steps>
```

**Output:** <expected result>

---

<!-- -- Optional sections, keep or remove as needed ---------- -->

## References

<!-- Use only when there are files in the references/ directory -->
<!-- Keep reference depth to one level, no nested references -->

- [<doc name>](references/<file>.md) — <one-sentence purpose>

<!-- -------------------------------------------------------- -->
