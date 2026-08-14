# Anti-Patterns

> Collects the most common mistakes when writing aic skills, each with a corrected example.

---

## AP-01: description too vague

**Wrong**
```yaml
description: Helps with database operations.
```

**Problem:** Verbs like "helps", "assists", "handles" have no semantic value to the agent. Without Use when, the agent does not know when to trigger.

**Fix**
```yaml
description: >
  Run database migrations, optimize slow queries, and manage connection configuration.
  Use when user mentions database migration, schema changes, or slow query optimization.
  Do NOT use for Redis/MongoDB or application-layer ORM code.
```

---

## AP-02: description describes implementation, not trigger scenarios

**Wrong**
```yaml
description: Uses pdfplumber to extract text from PDF files.
```

**Problem:** Engineers do not say "use pdfplumber to process a PDF", they say "parse this PDF for me". The description should match how users ask questions, not implementation details.

**Fix**
```yaml
description: >
  Extract text, tables, and form data from PDFs.
  Use when user asks about PDFs, mentions .pdf files, needs form filling,
  or says parse this file or extract PDF content.
  Do NOT use for image OCR or Word/Excel file processing.
```

---

## AP-03: missing version field

**Wrong**
```yaml
---
name: log-analyzer
description: Analyze log files...
tags: [ops]
---
```

**Problem:** aic requires the version field. Without it, aic install will refuse to install and report an error.

**Fix**
```yaml
---
name: log-analyzer
version: 1.0.0
description: Analyze log files...
tags: [ops]
---
```

---

## AP-04: env-required: true but missing env-vars declaration

**Wrong**
```yaml
---
name: database-ops
version: 1.0.0
description: ...
env-required: true
# forgot to declare env-vars
---

Connect to {{DB_HOST}}, user {{DB_USER}}
```

**Problem:** validate.sh will report an error. Without env-vars, the skill cannot specify which variables it needs, and aic env check cannot prompt engineers to fill them in.

**Fix**
```yaml
---
name: database-ops
version: 1.0.0
description: ...
env-required: true
env-vars:
  - name: DB_HOST
    description: Database host address
    required: true
    target: skill
  - name: DB_USER
    description: Database username
    required: true
    target: skill
---
```

---

## AP-04B: variable name format error or duplicate

**Wrong**
```yaml
env-vars:
  - name: api_key
    description: API key
    required: true
    target: skill
  - name: API-KEY
    description: Duplicate API key alias
    required: true
    target: skill
  - name: api_key
    description: Repeated variable
    required: true
    target: skill
```

**Problem:** Variable names must match ^[A-Z][A-Z0-9_]*$, are case-sensitive, and must not be duplicated within the same declaration.

**Fix**
```yaml
env-vars:
  - name: API_KEY
    description: API key
    required: true
    target: skill
```

---

## AP-05: real sensitive values written in the body

**Wrong**
```markdown
# Database Operations
Connection info:
- Host: 10.0.1.100
- Password: prod_secret_2024
```

**Problem:** SKILL.md is committed to the repository; anyone with access can see it. Real values are a high-risk leak.

**Fix**
```markdown
# Database Operations
Environment variable notes:
- DB_HOST: database connection entry point; if missing, stop and prompt the user to fill it in
- DB_PASSWORD: database password; if missing, stop and prompt the user to fill it in
```

---

## AP-06: directory name does not match the name field

**Wrong**
```
skills/common/pdf_processing/   <- underscore
    SKILL.md  -> name: pdf-processing   <- hyphen
```

**Problem:** aic loads skills by directory name; if the names do not match, the skill will not be recognized correctly.

**Fix rule:** The directory name and name field must be **exactly the same**, using **lowercase kebab-case**:
```
skills/common/pdf-processing/
    SKILL.md  -> name: pdf-processing  OK
```

---

## AP-07: SKILL.md body exceeds 500 lines

**Wrong:** Putting the complete operations manual, API documentation, and example collection into the SKILL.md body.

**Problem:** Every time the skill triggers, the entire body loads into the context window. 500 lines is about 5000 tokens; going longer significantly consumes the agent available context, affecting other skills and conversation content.

**Fix principle:**
- SKILL.md is a cheat sheet, not complete documentation
- Reference content, detailed specs, and example collections go into the references/ directory
- The body keeps only the core workflow and the most critical decision criteria

```
skill/
+-- SKILL.md              <- core workflow, < 500 lines
+-- references/
    +-- api-reference.md  <- detailed API docs, loaded on demand
    +-- examples.md       <- complete example collection, loaded on demand
```

---

## AP-08: nested reference chains in references/

**Wrong**
```markdown
<!-- SKILL.md -->
See [spec A](references/spec-a.md)

<!-- references/spec-a.md -->
More details in [spec B](references/spec-b.md)

<!-- references/spec-b.md -->
Also see [spec C](references/spec-c.md)
```

**Problem:** The agent needs multiple reads to get complete information, increasing context consumption, and reference chains are prone to breaking.

**Fix:** Files in references/ should be self-contained; reference depth should not exceed one level.

---

## AP-09: description boundary unclear with adjacent skills

**Wrong scenario:** A project has both database-ops (operations) and database-migration (migration-specific), but both descriptions say "run database migrations", causing the agent to randomly trigger one.

**Fix:** Exclude each other in both skills descriptions:

```yaml
# database-ops description
description: >
  Database daily operations: query optimization, connection config, index management.
  Use when optimizing queries, managing connections, or tuning database performance.
  Do NOT use for schema migrations (use the database-migration skill).

# database-migration description
description: >
  Run database schema migrations and manage migration script versions.
  Use when running migrations, writing migration scripts, or rolling back schema changes.
  Do NOT use for query optimization or routine database operations.
```

---

## AP-10: incomplete adapter layer files

**Wrong:** Created adapters/claude/SKILL.md but only wrote the allowed-tools frontmatter, with an empty body.

**Problem:** Adapter layer files are complete standalone files; no field merging is done. An empty body means Claude Code reads a skill with no instructions.

**Fix:** Adapter layer files must contain complete frontmatter + body. You can copy the body from the main SKILL.md and add Claude-specific fields:

```yaml
---
name: database-ops
version: 1.2.0
description: >   # keep consistent with main SKILL.md
  ...
allowed-tools: [Bash, Read]   # Claude Code specific field
---

# Database Ops (Claude Code version)
[complete body, same as main SKILL.md or with targeted modifications]
```
