
# Incremental Update Operation Spec

## Core Principle

**Append only; do not rewrite history.** AI tools can trace project progress through historical state; once rewritten, the context chain breaks.

**File path convention:** dev-plan.md is always at the project root; does not move with incremental updates.

---

## Operation Allowance Matrix

| Operation | Allowed | Notes |
|------|------|------|
| Append new Phase | yes | numbering continues; content is new |
| Append new Task | yes | append at the end of the corresponding Phase |
| Modify not-started Task content | yes | strikethrough original content; write new content |
| Append change record | yes | append only; do not modify historical entries (truncate oldest when over 5) |
| Update architecture diagram / project structure | yes | full update allowed; must include change description |
| Modify completed Task (checkmark) | caution | only Notes can be appended; do not modify original content |
| Modify existing Issue number | no | forbidden; would be inconsistent with GitLab status |
| Delete historical change records | no | forbidden (auto-truncate oldest when over 5; do not manually delete) |
| Rewrite completed Phase content | no | forbidden (completed Phases should be handled via archiving) |
| Move dev-plan.md file location | no | forbidden; always at project root |

---

## Change Record Format

Each incremental update must append a row to the `## Change Log` table at the file header:

```markdown
## Change Log
| Version | Date       | Change description                          |
|------|------------|-----------------------------------|
| v1   | 2026-01-10 | Initial version, 3 Phases, 12 Tasks   |
| v2   | 2026-01-15 | Added Phase 4 (aic env commands), 3 new Tasks |
| v3   | 2026-01-20 | Adjusted Task 2.3 estimate (4h -> 6h), added technical risk note |
```

**Rules:**
- Version number increments (v1 -> v2 -> v3 ...)
- Date in YYYY-MM-DD format
- Change description concise (one or two sentences)
- Keep only the latest 5 records; older ones auto-truncated

---

## Modifying Existing Task Content

When Task content changes but the Task has not started, preserve original content and annotate:

```markdown
#### Task 2.3: Implement GitLab repository clone/pull
- **Goal:** ~~Pull from GitLab to local cache~~ Support SSH and HTTPS dual-protocol pull; 30s timeout
- **Files involved:** `internal/registry/client.go`
- **Input:** Task 2.1 completed
- **Output:** `FetchRegistry(branch string) error`
- **Estimate:** ~~4 hours~~ 6 hours (HTTPS certificate handling more complex than expected)
- **Issue:** #(pending)
- **Note:** SSH private key path read from ~/.aic/config.toml; HTTPS needs self-signed cert handling
```

---

## Appending Note to Completed Task

Tasks with existing Issue numbers or checkmark marks can only have Notes appended at the end:

```markdown
#### Task 1.2: Implement .aicrc read/write
- **Goal:** ... (original content unchanged)
- **Issue:** #12 completed
- **Note (2026-01-18):** Found BOM encoding issue; fixed in #28
```

---

## Stage Status Markers

When a Phase completes, add a status marker after the title (do not modify Tasks within the Phase):

```markdown
### Phase 1: Core Foundation Modules | Estimated: 5 days | Priority: P0 | completed

### Phase 2: install command | Estimated: 7 days | Priority: P0 | in progress

### Phase 3: TUI interface | Estimated: 8 days | Priority: P1 | not started
```

---

## Relationship with Archiving

When a Phase completes, do not continue modifying that Phase content in dev-plan.md. Instead:

1. Confirm all Tasks within the Phase are marked as completed
2. Execute Phase archive operation (see references/archive-guide.md)
3. Phase content moves to `docs/dev-plan-archive/phase-{N}.md`
4. Delete the Phase block from dev-plan.md

This keeps the active document length bounded while preserving complete history.

---

## Incremental Update Checklist

Confirm before executing incremental update:

- [ ] Scope of this change is clear (which Phases/Tasks are affected)
- [ ] Change log table has a new entry appended (version number +1)
- [ ] Not-started Task modifications: original content has strikethrough; new content written
- [ ] Completed Tasks: only Notes appended; original content unchanged
- [ ] New Task numbering continues from the current maximum
- [ ] Architecture diagram/project structure updates: change date and reason noted at section end
- [ ] dev-plan.md file location is still at project root (not moved)
- [ ] If dev-plan.md exceeds 400 lines, consider executing Phase archive instead of continuing incremental updates
