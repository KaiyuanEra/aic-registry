
# New vs Legacy Project Detection Logic

## Detection Flow

```
Step 1: Detect local signals
  Read docs/dev-plan.md (if it exists)
  Count Issue field status:
    All are "#(pending)" -> new project signal +1
    Some have numbers     -> legacy project signal +1
    File does not exist   -> neutral

Step 2: Detect GitLab signals
  GET /api/v4/projects/{id}/milestones
  Result is empty (count=0) -> new project signal +1
  Result is non-empty       -> legacy project signal +1

Step 3: Detect user intent
  User says "new project" / "from scratch" / "full creation" -> new project signal +2 (high weight)
  User says "supplement" / "new" / "this sprint"             -> legacy project signal +2

Step 4: Decision
  New project signals > legacy project signals -> full creation mode
  Legacy project signals > new project signals -> incremental maintenance mode
  Signals are equal (cannot determine)         -> show differences, ask user
```

---

## Output Template When Showing Differences to User

```
Cannot auto-determine project type; please choose:

  [1] Full creation mode (new project)
      Will create: 3 milestones + 12 issues
      Use case: GitLab project is empty, or needs re-initialization

  [2] Incremental maintenance mode (legacy project)
      Will create: 1 new milestone + 3 pending issues
      Skip: 9 tasks that already have issue numbers
      Use case: project already has milestones and issues; only sync new additions

Enter 1 or 2:
```

---

## Incremental Mode Deduplication Logic

```
Milestone deduplication:
  GET all existing milestones; extract title list
  For each Phase to create:
    Title matches exactly -> skip; record existing milestone ID (for issue linking)
    No match -> create new milestone

Issue deduplication:
  GET all opened issues (state=opened); extract title list
  For each Task to create:
    Title matches exactly -> skip; output "already exists: #xx"
    No match -> create new issue

Note: closed issues (state=closed) also need checking to avoid duplicate creation
  Add state=all parameter when GETting to retrieve all states
```

---

## Output Format (after incremental mode execution)

```
aic glab-manage -- backend-api (incremental maintenance mode)

  Phase 4: aic env commands  ->  Milestone #4 created successfully

  [Phase 4] Implement aic env list command      ->  #45
  [Phase 4] Implement aic env add interactive input   ->  #46
  [Phase 4] Implement env-required rendering logic  ->  #47

  Skipped (already have issues):
    [Phase 1] Implement SKILL.md frontmatter parsing  ->  #12 (existing)
    [Phase 2] Implement GitLab clone/pull          ->  #18 (existing)
    ...(9 skipped total)

  ------------------------------------------------
  Created: 1 milestone, 3 issues
  Skipped: 9 issues (already exist)
  Writing back to dev-plan.md...  done
  Auto-commit: docs: sync GitLab issue numbers to development plan  done
```
