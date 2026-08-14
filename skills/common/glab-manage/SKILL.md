---
name: glab-manage
version: 3.0.1
description: >
  Create GitLab issues from a development plan, link them to an existing milestone, and write
  issue numbers back to dev-plan.md.
  Use when creating GitLab issues, syncing a dev plan to GitLab, or when user mentions create
  issue, sync plan to GitLab, glab, GitLab issue, issue number writeback, sync tasks, create
  issues for this sprint, close issue.
  Do NOT use for local git commit (use git-commit skill), only viewing GitLab info without
  creating, push/pull operations, or creating milestones.
tags: [gitlab, project-management, dev-workflow]
env-required: true
env-vars:
  - name: GITLAB_URL
    description: GitLab instance URL, e.g. https://git.ifogging.cn
    required: true
    default: "https://git.ifogging.cn"
    target: skill
  - name: GITLAB_TOKEN
    description: Personal Access Token with api scope (issue creation permission)
    required: true
    target: skill
  - name: GITLAB_PROJECT_ID
    description: Project numeric ID (preferred) or path, e.g. rd/backend/my-project
    required: true
  - name: GITLAB_ASSIGNEE_ID
    description: >-
      GitLab user numeric ID of the default assignee. Query method: curl -s -H "PRIVATE-TOKEN:<token>"
      "<GITLAB_URL>/api/v4/user" | python3 -m json.tool | grep id,
      or GitLab UI: avatar -> Edit profile -> User ID at the top of the page
    required: true
    target: skill
---

# glab-manage

Create GitLab issues from the Phase/Task structure in docs/dev-plan.md, link them to an existing milestone, and write issue numbers back to the plan document.

**Correspondence:** Task -> Issue (milestones are only linked, never auto-created)

---

## Milestone Selection Strategy

**Never auto-create milestones.** Query existing project milestones before execution:

```
1. Query all active milestones for the project
2. If only one -> use it directly, inform the user
3. If multiple -> default to the most recently created one, show it for user confirmation
                -> user may specify a different milestone
4. If none -> stop, prompt the user to create a milestone in GitLab first
```

> Warning: no milestones in the project; cannot create issues.
> Please create a milestone in the GitLab project page (Plan -> Milestones), then re-run.

**When ambiguous, you must ask the user.** Never guess.

---

## New Project vs Legacy Project Detection

```
New project signals (full creation):
  1. All Task Issue fields in dev-plan.md are "#(pending)"
  2. User explicitly says "new project" / "from scratch"

Legacy project signals (incremental maintenance):
  1. Some Tasks in dev-plan.md already have issue numbers
  2. User explicitly says "supplement" / "new requirements" / "this sprint"

When unclear: show both mode differences and ask the user to choose
```

See [references/new-vs-legacy.md](references/new-vs-legacy.md) for detailed logic.

---

## API Call Strategy

Priority: **GitLab Web API (curl) > glab CLI > prompt user to configure**

```bash
# Auto-detect before execution:
# 1. GITLAB_TOKEN exists -> use Web API
# 2. glab in PATH -> use glab CLI
# 3. Neither -> prompt configuration steps
```

**Script generation rules (AI must strictly follow):**

| Rule | Reason |
|------|------|
| Use absolute path /usr/bin/curl for curl | Claude Code bash has a minimal PATH; curl may not be found |
| Use absolute path /usr/bin/jq for jq | Same as above |
| Separate response body and status code: -o file -w "%{http_code}" | Never use curl ... | jq; avoids stderr/progress info polluting the pipe |
| Validate with jq empty before parsing | GitLab returns HTML on 401/502; passing it to jq causes parse errors |
| Non-200/201 status code: print raw response and exit immediately | Quickly identify token expiry, wrong project ID, or network issues |

See [references/api-reference.md](references/api-reference.md) for the full defensive call template.

---

## Issue Weight Rules

**Unit:** half-day (4 hours) = 1 weight

| Estimated hours | Weight |
|----------|--------|
| <= 4h | 1 |
| 5-8h | 2 |
| 9-12h | 3 |
| 13-16h | 4 |
| Each additional 4h | +1 |

**Hours source (by priority):**

1. Extract from the corresponding Task Estimated field in dev-plan.md; formula: weight = ceil(hours / 4)
2. When not extractable, estimate a reasonable value from the task title and description, **show it for user confirmation before using**; never write silently

---

## Issue Creation Granularity

Confirm granularity before creating (ask the user if unspecified):

| Granularity | Description | Use case |
|------|------|----------|
| **Phase granularity** (recommended) | Create one issue per Phase; Tasks become checklist items in the description | Progress reporting, milestone tracking |
| **Task granularity** | Create one issue per Task | Fine-grained division, multi-person collaboration |

Both granularities can be mixed: in the same operation, some Phases use Phase granularity while others use Task granularity.

---

### Phase Granularity Issue Spec

**Title format:**
```
[Task] {Phase feature name}
Example: [Task] User login and permission validation
```

**Description format (auto-generated from dev-plan.md):**
```
- [ ] Task 1.1: {Task name} (estimated {n}h)
- [ ] Task 1.2: {Task name} (estimated {n}h)
- [ ] Task 1.3: {Task name} (estimated {n}h)

## Acceptance Criteria
{Summarize each Task output deliverable; one sentence describing the Phase overall deliverable}
```

**Weight:** Sum all Task Estimated hours under the Phase, then convert: weight = ceil(total_hours / 4)

**Labels:** Same three-category label rules as Task granularity; type defaults to type::task

---

## Issue Title Prefix

Title prefix is determined by **type** and **source**:

| Type | From dev-plan (has Phase info) | No Phase info |
|------|-------------------------------|---------------|
| task | `[Task Phase 2.5] description` | `[Task] description` |
| bug  | `[Bug] description` | `[Bug] description` |
| prd  | `[PRD] description` | `[PRD] description` |

- Phase number extracted from the Phase structure in dev-plan.md (e.g. Phase 2.5 -> `Phase 2.5`)
- Bug and PRD types always use short prefixes without Phase numbers

---

## Issue Label Rules (three required categories)

Every issue must have all three label categories:

### 1. Priority label (choose one)

| Label | Meaning |
|------|------|
| `P0` | Urgent |
| `P1` | High |
| `P2` | Medium |
| `P3` | Low |

### 2. Type label (choose one)

| Label | Meaning |
|------|------|
| `type::task` | Task |
| `type::bug` | Defect |
| `type::prd` | Requirement |

### 3. Status label (choose one by type)

**type::task:**

| Label | Meaning |
|------|------|
| `task::todo` | To do |
| `task::doing` | In progress |
| `task::done` | Completed |

**type::bug:**

| Label | Meaning |
|------|------|
| `bug::open` | To fix |
| `bug::fixing` | Fixing |
| `bug::close` | Closed |

**type::prd:**

| Label | Meaning |
|------|------|
| `prd::todo` | To do |
| `prd::doing` | Designing |
| `prd::done` | Completed |

**Default initial status on issue creation:**
- task -> `task::todo`
- bug -> `bug::open`
- prd -> `prd::todo`

**Label collection interaction:** If the user does not specify priority, show P0-P3 options for confirmation; never assume.

---

## Issue Close Flow

When executing a close operation, **update the status label first, then close the issue**:

```
1. Query the issue current labels; identify the status label
2. Remove the old status label
3. Add the terminal status label:
     type::task -> task::done
     type::bug  -> bug::close
     type::prd  -> prd::done
4. Call the close API to close the issue
```

See [references/api-reference.md](references/api-reference.md) for API call order.

---

## Workflow

### Full Creation (new project)

1. **Query milestone** — determine the milestone ID per the selection strategy
2. **Read** docs/dev-plan.md; extract all Phases and Tasks
3. **Confirm granularity** — Phase or Task granularity (see above)
4. **Collect label info** — confirm priority (batch can use a unified default)
5. **Create issues** — create per selected granularity, link milestone, apply three label categories
6. **Write back numbers** — write issue numbers back to dev-plan.md
7. **Auto-commit** — `docs: sync GitLab issue numbers to development plan`

### Incremental Maintenance (legacy project)

1. **Query milestone** — same as above
2. **Read** dev-plan.md; filter Phases or Tasks whose Issue field is still `#(pending)`
3. **Confirm granularity** — same as above
4. **Only create** missing issues
5. **Skip** entries that already have issue numbers and already-closed issues
6. **Write back + commit** (same as above)

---

## Issue Description Template

```markdown
## Task Objective
{Extracted from dev-plan.md Task description}

## Files Involved
{Extracted from dev-plan.md; leave empty if none}

## Acceptance Criteria
- [ ] {acceptance item}

## Notes
{Other notes}
```

---

## Writeback Mechanism

**Task granularity writeback (original behavior):**
```
From: - **Issue:** #(pending)
To:   - **Issue:** #42
```

**Phase granularity writeback (new):**

Write back to the Phase title line, format:
```
### Phase 1: User login and permission validation | Estimated: 4 days | Priority: P1 | Issue: #12 | Status: in progress
```

After the issue is closed, sync the status field:
```
### Phase 1: User login and permission validation | Estimated: 4 days | Priority: P1 | Issue: #12 | Status: completed ({YYYY-MM-DD})
```

**Execution:** Call scripts/writeback.sh; on failure, output a manual fill-in mapping table without interrupting the flow.

---

## Common Edge Cases

| Case | Handling |
|------|----------|
| No dev-plan.md | Degrade: collect info via direct dialogue, create one by one; suggest running dev-plan skill first |
| No milestone | Stop; prompt user to create a milestone in GitLab first |
| GITLAB_TOKEN insufficient permissions | Explain api scope is needed; provide Token creation link |
| Wrong project ID | Call GET /api/v4/projects?search=xxx to help the user confirm the correct ID |
| Network timeout | Record progress of already-created items; prompt user to skip them on retry |
| Duplicate issue title | Query before creating; skip if title matches exactly; output skipped list |
| No status label on close | Warn user; ask whether to close directly or add labels first |
