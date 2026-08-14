# Phase Archive Operation Guide (v2.0)

This document details how to execute Phase-level archiving to keep dev-plan.md length bounded.

---

## 1. When to Trigger Archiving

### Document Size Monitoring

- **< 300 lines**: normal state; no archiving needed
- **300-400 lines**: yellow warning; consider archiving completed Phases
- **> 400 lines**: red warning; strongly recommend executing archive immediately

### User-Initiated

```
Trigger phrases:
  "archive Phase N"
  "Phase N is complete, simplify the development plan"
  "dev-plan is too long, archive completed parts"
  "clean up completed Phases"
```

---

## 2. Pre-Validation (all must pass)

### Validation 1: All Task Status Within the Phase

**Check content:** whether each Task of the target Phase is marked as completed

**Execution:**
```
1. Open dev-plan.md
2. Locate the "### Phase {N}:" section
3. Check each Task status field one by one
4. Confirm all are marked as completed
```

**Failure handling:**
```
If incomplete Tasks exist:
  Block archiving
  Output:
    Incomplete Tasks:
    - Task N.1: {task name} - Status: in progress
    - Task N.3: {task name} - Status: not started

    Please complete the above Tasks or manually mark them as completed before archiving.
```

### Validation 2: GitLab Milestone Status

**Check content:** whether the corresponding GitLab Milestone is closed (only when the project uses GitLab and has a corresponding Milestone)

**Execution:**
```
1. Check whether Phase {N} Tasks in dev-plan.md have Issue numbers
   -> no Issue numbers (GitLab not used) -> skip this validation
2. Find Phase {N} Milestone number in dev-plan.md
3. Visit GitLab project -> Milestones
4. Find the corresponding Milestone; check if status is "Closed"
```

**Failure handling:**
```
If Milestone exists and is still "Open":
  Block archiving
  Output:
    GitLab Milestone not closed:
    Milestone: Phase 1: Foundation data layer (#1)
    Status: Open

    Please close this Milestone in GitLab first, or run:
    glab milestone update {milestone_id} --state closed

    If you confirm the Milestone does not need closing, you can skip this validation and continue archiving.
```

### Validation 3: Subsequent Phase Dependency References

**Check content:** whether Tasks in remaining Phases reference the target Phase Task numbers

**Execution:**
```
1. Open dev-plan.md
2. Locate all Phases after the target Phase
3. Search for the target Phase Task numbers in each Task "Input dependency" field
   e.g.: search "Task 1.1", "Task 1.2", etc.
```

**Failure handling:**
```
If dependency references exist:
  Block archiving
  Output:
    Subsequent Phases have dependency references:
    - Phase 2, Task 2.1: Input dependency -> Task 1.3
    - Phase 3, Task 3.2: Input dependency -> Task 1.5

    Please update these Task dependency descriptions first (change to "no dependency" or reference other Tasks),
    then execute archiving.
```

### Validation 4: Archive File Conflict

**Check content:** whether `docs/dev-plan-archive/phase-{N}.md` already exists

**Execution:**
```
1. Check project directory structure
2. View docs/dev-plan-archive/ directory
3. Confirm whether phase-{N}.md exists
```

**Failure handling:**
```
If file already exists:
  Block archiving
  Output:
    This Phase is already archived:
    docs/dev-plan-archive/phase-1.md already exists

    Please confirm whether re-archiving is needed.
    If overwriting, please manually delete the old file or use a different Phase number.
```

---

## 3. Execution Steps

After all validations pass, execute the following steps. **If any step fails, roll back entirely.**

### Step 1: Create Archive Directory

```bash
mkdir -p docs/dev-plan-archive/
```

**Check:** confirm directory created

### Step 2: Generate Archive File

**File path:** `docs/dev-plan-archive/phase-{N}.md`

**File content structure:**

```markdown
# Phase {N} Archive Record

Archive date: {YYYY-MM-DD}
Completion date: {actual completion date}
Planned duration: {n} days
Actual duration: {n} days
Linked Milestone: #{Milestone ID}
Task completion: {M}/{M}

---

### Phase {N}: {stage name} | Estimated: {n} days | Priority: P{n}

**Goal:** {what this Phase delivers; why it was done first}

#### Task N.1: {task name}
- **Goal:** {what to implement; acceptance criteria}
- **Files involved:** `path/to/file.go`, `path/to/other.go`
- **Input dependency:** {what it depends on}
- **Expected output:** {what it produces}
- **Estimate:** {n} hours
- **Issue:** #{n}
- **Status:** completed
- **Note:** {edge cases, technical risks} (optional)

#### Task N.2: {task name}
...(subsequent Tasks fully preserved)
```

**Operation:**
```
1. Copy the complete Phase content from dev-plan.md
   (from "### Phase {N}:" to just before the next "### Phase")
2. Add metadata at the file header (archive date, completion date, duration, Milestone, Task completion)
3. Write the complete content to docs/dev-plan-archive/phase-{N}.md
```

### Step 3: Delete Target Phase Block from dev-plan.md

**Operation:**
```
1. Open dev-plan.md
2. Locate the "### Phase {N}:" line
3. Delete all content from that line to just before the next "### Phase"
   (including Phase title, all Tasks, and trailing blank lines)
4. Preserve "### Phase {N+1}:" and subsequent content
```

**Check:** confirm dev-plan.md no longer contains the target Phase content

### Step 4: Update Archived Declaration and Index Table at Top of dev-plan.md

**Operation:**
```
1. Open dev-plan.md
2. Locate the "> Last updated: ..." line in the file header
3. Add or update the "> Archived:" line below it

Example:
> Last updated: 2026-06-01 | Version: v4 | Status: in progress
> Archived: Phase 1 (Foundation data layer) -> docs/dev-plan-archive/phase-1.md
>           Phase 2 (Git repository and cache) -> docs/dev-plan-archive/phase-2.md

4. Locate the "## Archived Phase Index" table
5. Append a row to the table:

| Phase 1 | Foundation data layer | 2026-05-12 | 6 | #1-#6 |

   Where:
   - Phase: target Phase number
   - Stage name: Phase name
   - Completion date: actual completion date
   - Task count: total Tasks in this Phase
   - Issue range: Issue number range for this Phase (e.g. #1-#6)
```

**Check:** confirm archived declaration and index table updated

### Step 5: Append Archive Record to Change Log

**Operation:**
```
1. Open dev-plan.md
2. Locate the "## Change Log" table
3. Append a row at the top (latest record) of the table:

| v{n} | {YYYY-MM-DD} | Phase {N} archived -> docs/dev-plan-archive/phase-{N}.md |

4. If change log exceeds 5 entries, delete the oldest one
```

**Check:** confirm change log appended

### Step 6: Output Archive Report

```
Phase {N} successfully archived

Archive file: docs/dev-plan-archive/phase-{N}.md
dev-plan.md reduced by ~{N} lines (from {old_lines} lines -> {new_lines} lines)
Archived Phase index table updated: Phase {N} added to the table
Current active plan: Phase {M} to Phase {K} ({total_tasks} Tasks total)

Recommended next steps:
1. Execute git add and git commit to commit changes
2. To sync to GitLab, use the glab-manage skill
3. If dev-plan.md still exceeds 400 lines, consider archiving more Phases
```

---

## 4. Rollback Handling

If any step fails during execution, perform the following rollback:

```
1. Delete the created docs/dev-plan-archive/phase-{N}.md file
2. Restore dev-plan.md to its pre-execution state
   (if modified, use git checkout dev-plan.md to restore)
3. Output error message and failure reason
4. Prompt user to fix the issue and retry
```

---

## 5. FAQ

### Q1: Can I archive only some Tasks within a Phase?

**A:** No. Archiving is a Phase-level operation; the entire Phase must be archived together. Reasons:
- Partial Task archiving leaves incomplete Phase blocks in dev-plan.md
- AI tools reading the current Phase would have incomplete context
- Increases document maintenance complexity

### Q2: Can I restore after archiving?

**A:** Yes. The archive file is saved at `docs/dev-plan-archive/phase-{N}.md` and can be manually copied back to dev-plan.md. However, it is recommended to view original content through git history.

### Q3: How to find archived Tasks?

**A:** Search through the "Archived Phase Index" table at the top of dev-plan.md:
1. Open dev-plan.md; view the "Archived Phase Index" table
2. Locate the corresponding Phase by Issue range or stage name
3. Open `docs/dev-plan-archive/phase-{N}.md` to view full Task content

### Q4: How do other skills find Issue numbers after archiving?

**A:** Other skills (glab-manage / git-commit) search through the index table in dev-plan.md:
1. First search Tasks in active Phases in dev-plan.md
2. Not found -> search the "Archived Phase Index" table at the top of dev-plan.md; locate phase-N.md by Issue range
3. Open the corresponding phase-N.md to get specific Issue numbers
4. Still not found -> prompt user to provide manually

---

## 6. Checklist

Before archiving, confirm:

- [ ] All Tasks in the target Phase are marked as completed
- [ ] The corresponding GitLab Milestone is closed
- [ ] Tasks in subsequent Phases do not depend on the target Phase Tasks
- [ ] `docs/dev-plan-archive/phase-{N}.md` does not exist (or is backed up)
- [ ] dev-plan.md is backed up or in git (for rollback)
- [ ] Sufficient disk space to create new files

After archiving, confirm:

- [ ] `docs/dev-plan-archive/phase-{N}.md` is created
- [ ] dev-plan.md no longer contains the target Phase content
- [ ] Archived declaration (file header `> Archived:`) is updated
- [ ] Archived Phase index table has a new row appended
- [ ] Change log is appended
- [ ] dev-plan.md line count has decreased
- [ ] File format is correct (valid Markdown syntax)
