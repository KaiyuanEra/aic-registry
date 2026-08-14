# Description Pattern Library

> The description is the **only trigger mechanism** for a skill.
> Claude Code aggregates every skill name + description into a meta-tool passed to the agent,
> relying purely on LLM forward-pass semantic matching — no regex, no classifier.
>
> **aic note:** Engineers ask questions in natural language. The LLM has cross-lingual semantic
> understanding, but colloquial phrasing is semantically farther from a formal description.
> **All skill descriptions must be written in English**, covering both technical terms and the
> natural-language keywords users actually type.

---

## Core Formula

```
[Verb phrase describing the core function].
Use when [positive scenario 1], [positive scenario 2], or when user mentions [keyword list].
Do NOT use for [exclusion scenario] or [easily confused adjacent scenario].
```

**All three parts are required:**
- Function segment -> tells the agent what the skill can do
- Use when segment -> tells the agent when to trigger (must include natural-language keywords users actually type)
- Do NOT use for segment -> prevents false triggers and draws boundaries with adjacent skills

**Writing in English is mandatory, not optional.** Standard template:

```yaml
description: >
  <English functional summary>.
  Use when <English technical scenario>, <English technical scenario>,
  or when user mentions <natural-language keyword>, <keyword>, or <command/term>.
  Do NOT use for <English exclusion scenario> or <English exclusion scenario>.
```

---

## Pattern 1: Action-first (most common)

Best for skills with a single, clear action.

```yaml
description: >
  Run database migrations, optimize slow queries, and manage connection configuration.
  Use when working with MySQL/PostgreSQL schema changes, running migrations,
  or when user mentions database migration, slow query, connection pool, or database performance.
  Do NOT use for Redis, MongoDB, or writing application-layer ORM code.
```

**Key points:**
- Lead with a verb (run, generate, analyze, manage)
- Mix technical terms and natural-language keywords in Use when to cover how engineers actually phrase requests

---

## Pattern 2: Scenario enumeration

Best for skills covering multiple independent scenarios, each worth its own mention.

```yaml
description: >
  Docker container operation guidelines.
  Use when: (1) writing or reviewing a Dockerfile, (2) debugging container startup failures,
  (3) configuring docker-compose multi-service, (4) analyzing image size.
  Do NOT use for Kubernetes deployment or CI/CD pipeline configuration.
```

**Key points:**
- Number the scenarios for clarity
- Each scenario uses a gerund phrase

---

## Pattern 3: Role perspective

Best for skills specific to a particular role or stage.

```yaml
description: >
  Code review guidelines for MR reviewers.
  Use when reviewing a pull request, providing code review comments,
  checking MR checklist, or when user asks to review an MR or take a look at a PR.
  Do NOT use for writing new code or fixing bugs (not in review context).
```

**Key points:**
- Clarify the role (reviewer vs developer) to reduce cross-role false triggers

---

## Pattern 4: Negation-first

Best when the skill name is easily confused with other common tasks. Lead with exclusions so the agent proactively recognizes boundaries.

```yaml
description: >
  Author new aic SKILL.md files.
  Do NOT use for: aic install/remove/sync commands, managing installed skills, or writing non-skill documentation.
  Use when creating a new skill from scratch, improving an existing skill description trigger,
  or designing the structure of a SKILL.md for aic compatibility.
```

**Key points:**
- When false-trigger risk is high, put Do NOT use for first
- Good for meta-skills (skills about skills)

---

## Pattern 5: Keyword injection

Best when user questions rely heavily on specific terminology.

```yaml
description: >
  Frontend build pipeline configuration and debugging.
  Use when user mentions build failure, webpack error, vite config, hot reload not working,
  bundle size too large, tree shaking, or frontend will not start.
  Do NOT use for backend API development or database operations.
```

**Key points:**
- Collect the colloquial expressions engineers actually use
- Quoted phrases are closer to real trigger words

---

## English Writing Guidelines

Descriptions should cover the range of expressions users naturally type:

```yaml
# Good: covers technical terms and natural phrasing
Use when user mentions database migration, schema migration, or running db migrate.

# Poor: too narrow, may not trigger on natural-language questions
Use when user mentions database migration or schema changes.
```

---

## Description Length Guidelines

| Scenario | Suggested word count |
|------|----------|
| Single function, clear boundaries | 30 to 60 words |
| Multiple scenarios, needs enumeration | 60 to 100 words |
| Boundary ambiguity with multiple skills | 100 to 150 words (strengthen exclusion segment) |
| Over 150 words | Re-examine whether the skill scope is too broad; consider splitting |

---

## Description Self-Check Checklist

Confirm each item after writing:

- [ ] Starts with a verb or functional noun (not "This skill" or "A tool that")
- [ ] Includes Use when + at least 2 positive scenarios
- [ ] Includes Do NOT use for + at least 1 exclusion scenario
- [ ] Covers natural-language keywords and technical terms
- [ ] Passes scripts/description-score.sh (score >= 60)
- [ ] No vague verbs (help, assist, handle, deal with)

---

## Anti-Example Comparison

```yaml
# Vague function, no trigger scenario
description: Helps with database operations.

# Only describes implementation, no trigger context
description: Processes and analyzes log files using grep and awk.

# Too broad, will false-trigger
description: >
  Assists with backend development tasks.
  Use when doing backend work.

# Corrected rewrite
description: >
  Analyze application logs, extract error patterns, and summarize request volume trends.
  Use when debugging production errors, analyzing access logs,
  or when user mentions log analysis, error tracking, log grep, or check the logs.
  Do NOT use for structured database queries or metrics dashboards.
```
