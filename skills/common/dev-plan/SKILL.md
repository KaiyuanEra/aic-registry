---
name: dev-plan
version: 2.0.3
description: >
  Generate or incrementally update the project development plan document dev-plan.md, breaking down
  Phase/Task structure, with Phase-level archiving and document length management.
  Use when writing a development plan, breaking down a PRD into tasks, updating an existing plan,
  archiving completed phases, or when user mentions create a development plan, break down tasks,
  update plan, project planning, requirement breakdown, technical approach, task list, Phase division,
  dev-plan, PRD, milestone planning, archive Phase, or simplify plan.
  Do NOT use for creating GitLab Issues or Milestones (use glab-manage skill), git commit operations
  (use git-commit skill), or pure technical implementation questions.
tags: [planning, dev-workflow, docs]
env-required: false
---

# dev-plan

Generate or incrementally update `dev-plan.md` from requirement input, providing a stable development context anchor for AI tools. Also supports Phase-level archiving to keep the active document length bounded.

**Core value:** task-level breakdown (2-8 hours + specific file paths) = even low-parameter models can execute accurately.

**v2.0 additions:** Phase-level archiving mechanism + document size monitoring + pre-validation + fallback lookup.

---

## File Location Convention

```
project root/
+-- dev-plan.md                    <- active document (current + future Phases + archive index table)
+-- docs/
    +-- dev-plan-archive/
        +-- phase-1.md             <- completed Phase full archive file
        +-- phase-2.md
        +-- ...
```

**Initialization rules:**
- When creating dev-plan.md, the file location is the **project root**
- On first archive, automatically create the `docs/dev-plan-archive/` directory (if it does not exist)

**dev-plan.md structure:**
```markdown
# {Project Name} Development Plan

> Last updated: {date} | Version: v{n}
> Archived: Phase 1 -> docs/dev-plan-archive/phase-1.md

## Archived Phase Index

| Phase | Stage name | Completion date | Task count | Issue range |
|-------|--------|---------|--------|-----------|
| Phase 1 | Foundation data layer | 2026-05-12 | 6 | #1-#6 |
| Phase 2 | Git repository | 2026-05-20 | 5 | #7-#11 |

---

## Change Log
...

## 1. Project Overview
...
```

**Index table purpose:**
- Centrally records metadata for all archived Phases
- Provides Issue number ranges for quick lookup by glab-manage / git-commit
- Other skills need no modification; query directly from dev-plan.md

---

## Work Modes

### Mode 1: New

```
Detect whether dev-plan.md exists:

does not exist -> new mode
  collect input -> generate full document -> write to {project_root}/dev-plan.md
```

### Mode 2: Incremental Update

```
exists -> incremental mode
  read existing document -> identify change scope -> only modify affected sections
  append this change record to the changelog at the file header
  completed Tasks (checkmark or have Issue numbers) are not rewritten; only Notes can be appended
```

### Mode 3: Phase Archive (v2.0 addition)

```
user initiates archive request -> run pre-validation -> pass then execute archive flow
  Step 1: create docs/dev-plan-archive/ directory
  Step 2: generate phase-{N}.md archive file
  Step 3: delete target Phase block from dev-plan.md
  Step 4: update archived declaration at top of dev-plan.md
  Step 5: append archive record to change log
  Step 6: output archive report

See references/archive-guide.md
```

---

## Workflow

1. **Collect input** — user provides: requirement doc / PRD / feature description / existing codebase
2. **Determine mode** — detect whether `dev-plan.md` exists; choose new / incremental / archive mode
3. **Generate content** — output per document structure spec (see below)
4. **Write file** — call Write tool:
   - `file_path`: `{project_root}/dev-plan.md` (use Bash `pwd` to get absolute path)
   - `content`: generated full document text
5. **Document size check** — check line count after generation:
   - **< 300 lines**: normal; output completion prompt
   - **300-400 lines**: yellow warning; suggest archiving completed Phases
   - **> 400 lines**: red warning; strongly recommend executing Phase archive
6. **Prompt next steps** — after completion, prompt: use `glab-manage` skill to sync to GitLab, or use this skill to execute Phase archive

---

## Document Structure

File location: `{project_root}/dev-plan.md`

```markdown
# {Project Name} Development Plan

> Last updated: {YYYY-MM-DD} | Version: v{n} | Status: in progress
> Archived: Phase 1 -> docs/dev-plan-archive/phase-1.md (omit this line when no archives)

## Archived Phase Index

| Phase | Stage name | Completion date | Task count | Issue range |
|-------|--------|---------|--------|-----------|
| (none) | - | - | - | - (keep this placeholder row when no archives) |

---

## Change Log

| Version | Date | Change description |
|------|------|----------|
| v{n} | {date} | {change description} |

---

## 1. Project Overview
### 1.1 Background and Goals
### 1.2 Core User Scenarios (3-5 items)
### 1.3 Scope Boundaries (what to do / what not to do)

## 2. Technology Stack
| Layer | Technology | Version | Selection rationale |

## 3. Overall Architecture Design
### 3.1 Architecture Diagram (ASCII or Mermaid)
### 3.2 Module Responsibilities
### 3.3 Key Data Flows

## 4. Project Structure
(directory tree + one-sentence descriptions of key files)

## 5. Development Plan
### Phase 1: {feature name} | Estimated: {n} days | Priority: P0 | Issue: #(pending) | Status: in progress
#### Task 1.1: {verb phrase}
- Goal / Files involved / Input / Output / Estimate / Issue / Notes
```

**Permanently retained sections:** Chapters 1-4 (overview/tech stack/architecture/structure) are always retained in the active document and do not participate in archiving.

Detailed template in [assets/dev-plan.template.md](assets/dev-plan.template.md).

---

## Phase Naming Convention (mandatory)

Phase names must be **human-readable feature/problem descriptions**, not technical module names. Naming principles:

- **Implementing a feature**: describe what capability is delivered, from user/business perspective
- **Solving a problem**: describe what problem is fixed or what risk is eliminated
- **Fixing a bug**: describe the bug symptom or impact scope

| Non-compliant (technical module name) | Compliant (feature/problem description) |
|------------------------|------------------------|
| `Phase 1: Core Foundation Module` | `Phase 1: User Login and Permission Validation` |
| `Phase 2: CLI Interaction Layer` | `Phase 2: Command-Line Install and Config Wizard` |
| `Phase 3: Parser Refactor` | `Phase 3: Fix Undercounting When Multiple Windows Coexist` |
| `Phase 4: Performance Optimization` | `Phase 4: Reduce P99 Latency Under High Concurrency to Below 50ms` |

**Validation rule:** Phase names must not use pure technical terms (like `module`, `layer`, `refactor`, `optimization`) as the subject; must answer "after this Phase completes, what does the user/business get?"

---

## Task Split Core Standards

**Granularity:** completable in 2-8 hours + corresponds to 1-3 specific file changes

Each Task must satisfy:

| Check item | Example |
|--------|------|
| Task name is a verb phrase | OK: "Implement SKILL.md frontmatter parsing" / Bad: "Parser module" |
| Files involved specified to path | `internal/skill/parser.go` |
| Input dependency clear | "Depends on Task 1.2 completion" or "no dependency" |
| Output deliverable clear | function signature / interface / API endpoint |
| Estimate 2-8 hours | split further if exceeded |
| Acceptance criteria AI-self-verifiable | can run / test passes / output matches format |

Detailed split methods in [references/task-split-guide.md](references/task-split-guide.md).

---

## Incremental Update Constraints

- Change log is append-only; do not modify history (truncate oldest when over 5 entries)
- Tasks with existing Issue numbers are not rewritten; only Notes can be appended
- New Phases/Tasks are appended at the end; numbering is continuous
- When modifying existing Task content: strikethrough original content, then write new content

Detailed spec in [references/incremental-update.md](references/incremental-update.md).

---

## Phase Archive Flow (v2.0 addition)

### Trigger Conditions

User explicitly initiates archive request:
- "archive Phase N"
- "Phase N is complete, simplify the development plan"
- "dev-plan is too long, archive completed parts"

### Pre-Validation (all must pass)

**Validation 1: All Task status within the Phase**
- Check each Task of the target Phase
- All must be marked as completed
- List incomplete Tasks; block archiving

**Validation 1.5: Phase title line Issue status**
- Check whether the Phase title line Issue field has a number (not #(pending))
- Check whether the Status field is completed
- If not met, prompt: please close the corresponding Issue via glab-manage first; status will be written back automatically

**Validation 2: GitLab Milestone status**
- Check whether the corresponding Milestone is closed
- If not closed, prompt: please close the Milestone in GitLab first

**Validation 3: Subsequent Phase dependency references**
- Scan all Tasks in remaining Phases
- Check whether the Input dependency field references the target Phase Task numbers
- If references exist, list specific Tasks; prompt to update dependencies first

**Validation 4: Archive file conflict**
- Check whether `docs/dev-plan-archive/phase-{N}.md` already exists
- If it exists, prompt "this Phase is already archived; please confirm whether this is a duplicate operation"

### Execution Steps

After all validations pass, execute the following steps (if any step fails, roll back entirely):

```
Step 1: Create archive directory
  mkdir -p docs/dev-plan-archive/

Step 2: Generate archive file docs/dev-plan-archive/phase-{N}.md
  Includes: Phase metadata + full Phase content + all Task and Issue numbers

Step 3: Delete target Phase block from dev-plan.md
  Precisely delete from "### Phase {N}:" to just before the next "### Phase"

Step 4: Update archived declaration at top of dev-plan.md
  Append to the > Archived: line in the file header:
  Phase {N} ({stage name}) -> docs/dev-plan-archive/phase-{N}.md

Step 5: Append a row to the dev-plan.md change log
  | v{n} | {date} | Phase {N} archived -> docs/dev-plan-archive/phase-{N}.md |

Step 6: Output archive report
  Phase {N} archived
  Archive file: docs/dev-plan-archive/phase-{N}.md
  dev-plan.md reduced by ~{N} lines
  Current active plan: Phase {M} to Phase {K} ({N} Tasks total)
```

Detailed guidance in [references/archive-guide.md](references/archive-guide.md).

---

## Integration with Other Skills

### glab-manage skill Issue number lookup

```
1. First search active Phases in dev-plan.md (Chapter 5 Development Plan)
   -> found -> read Task Issue field

2. Not found (Task archived) ->
   search the "Archived Phase Index" table at the top of dev-plan.md
   -> locate the corresponding phase-N.md by Issue range
   -> open phase-N.md; find the corresponding Task Issue number

3. Still not found -> prompt user to provide Issue number manually
```

### git-commit skill context awareness

```
1. Match Task in dev-plan.md via changed file paths
   -> matched -> read Issue field; generate Refs/Closes footer

2. Not matched (Task archived) ->
   search the "Archived Phase Index" table at the top of dev-plan.md
   -> locate the corresponding phase-N.md by Issue range
   -> open phase-N.md; find the corresponding Task Issue number
   -> generate footer; note "(archived Task)"

3. Completely not found -> footer left empty; prompt engineer to fill manually
```

**Key point:** other skills need no modification; query directly from the index table in dev-plan.md

---

## Common Edge Cases

| Case | Handling |
|------|----------|
| User only gave a few sentences of description | output skeleton first; mark `{to be filled}` placeholders; ask for missing info |
| Existing codebase but no PRD | read directory structure and README; reverse-engineer existing architecture before planning |
| Complex Task dependencies | note prerequisite Task numbers in the Task Input field; do not draw graphs |
| Estimate time undetermined | write a range like `4-8 hours`; note uncertainty factors |
| dev-plan.md exceeds 400 lines | strongly recommend executing Phase archive; prompt user with specific steps |
