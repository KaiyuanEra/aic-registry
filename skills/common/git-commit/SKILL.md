---
name: git-commit
version: 1.0.4
description: >
  Generate standardized commit messages from git changes and development context, then execute the commit.
  Use when committing code, writing a commit message, or completing a development task,
  or when user mentions commit my code, write a commit message, stage and commit,
  code is done, task is complete, or git commit.
  Do NOT use for git push, merge, rebase, cherry-pick or other git operations,
  only viewing git status, or pulling remote code.
tags: [git, dev-workflow, commit]
env-required: false
---

# git-commit

Generate a standardized commit message from staged changes (`git diff --staged`) and development context, then confirm and execute the commit.

**Design principle:** link when possible, do not force it; serves developer reading habits.

---

## Pre-Execution Check

```
Staging area empty?
  yes -> prompt: please git add the target files first, then commit
  no  -> continue
```

---

## Context Awareness Chain

Detect in order; auto-infer associated Task and Issue:

```
1. Detect docs/dev-plan.md
   exists -> read in-progress Task list; extract "files involved" field

2. Cross-match changed file paths
   changed files intersection Task files -> infer associated Task and Issue number

3. Detect git branch name
   contains issue-{n} or #{n} -> extract Issue number

4. None of the above -> standalone mode; generate commit purely from diff content

Show detection results to the user for confirmation; do not link silently
```

---

## Commit Message Format

**Format:**
```
{type}({scope}): {English description}

{body (optional)}

{footer (optional)}
```

**type enum:**

| type | meaning | example scenario |
|------|------|----------|
| `feat` | new feature | implement new command, new module |
| `fix` | bug fix | fix symlink creation failure |
| `refactor` | refactoring | no behavior change, optimize structure |
| `docs` | documentation | update dev-plan.md, README |
| `chore` | engineering config | modify Makefile, dependency update |
| `test` | testing | add unit tests, fix tests |
| `perf` | performance optimization | reduce unnecessary API calls |

**Title line rules:**
- English description, verb-first, 20-50 characters
- scope uses module name, not file name
- no trailing period

**footer Issue linking:**
```
In progress (do not close): Refs #42
Completed and close:        Closes #42   <- determined by Step 5 Task completion status; do not judge manually
Multiple:                   Refs #42, #43 / Closes #44
New project no issues:      footer left empty
```

See [references/type-scope-guide.md](references/type-scope-guide.md) for detailed type/scope selection,
and [references/examples.md](references/examples.md) for scenario examples.

---

## Workflow

1. **Read changes** — `git diff --staged`; analyze changed files and modification nature
2. **Detect context** — run `scripts/context-detect.sh` to detect dev-plan and branch
3. **Generate draft** — output commit message and show confirmation UI:

```
+-- Suggested commit message -------------------------+
|                                                     |
|  feat(parser): implement SKILL.md frontmatter parsing|
|                                                     |
|  Add ParseSkill() function to parse YAML header and  |
|  extract name/version/description/env-required fields;|
|  return a clear error when version is not semver.    |
|                                                     |
|  Closes #42                                         |
|                                                     |
|  Changed files: internal/skill/parser.go (+120 -0)   |
|                 internal/skill/model.go  (+45 -3)    |
+-----------------------------------------------------+

[y] confirm commit  [e] edit then commit  [r] regenerate  [n] cancel
```

4. **Execute commit** — run `git commit` after user confirmation
5. **Sync dev-plan.md and close Issue** — after successful commit, if a Task was linked, ask whether that Task is complete:

```
Linked Task complete?
  yes -> run scripts/close-issue.sh <issue_number>
         script handles: 1. call GitLab/GitHub API to close Issue
                         2. update the corresponding Task status in dev-plan.md to "completed"
         commit message footer uses Closes #n
         append dev-plan.md changes to this commit (git commit --amend)
         or as a separate docs commit (user choice)
  no  -> status stays "in progress"; footer uses Refs #n; do not modify dev-plan.md

dev-plan.md does not exist -> skip this step
No Task linked              -> skip this step
```

> The script auto-infers the platform (GitLab/GitHub) and project path from `git remote origin`.
> Token read priority: current project `.aic/.aic-env` -> `~/.aic/aic-env` -> shell environment variables.
> When no token is found, **do not error or block the commit**; only skip the Issue close step and prompt configuration instructions.
> Recommend installing the `glab-manage` skill to manage `GITLAB_TOKEN` centrally (`aic env add GITLAB_TOKEN`).
> Preview without calling the API using `--dry-run`:
> `bash scripts/close-issue.sh 42 --dry-run`

6. **Prompt push** — ask whether to `git push` after commit (do not auto-execute)

---

## New Project vs Legacy Project

```
New project simplified mode (either condition):
  1. All Task Issue fields in dev-plan.md are "#(pending)"
  2. User explicitly says "no issues created yet"

  -> footer left empty; body optional; focus on correct title format

Legacy project standard mode:
  -> link Issues where possible; add body for complex changes; strict type/scope
```

---

## Common Edge Cases

| Case | Handling |
|------|----------|
| Changes span multiple Tasks | Split into multiple commits; only commit relevant files each time |
| Cannot determine type | Output change analysis; list candidate types for user to choose |
| Linked to multiple Issues | List all in footer: `Refs #42, #43` |
| dev-plan.md does not exist | Degrade to standalone mode; does not affect commit generation |
| Unexpected files staged | Show staged file list; prompt confirmation before continuing |
