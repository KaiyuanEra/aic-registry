
# type/scope Selection Guide

## type Selection Decision Tree

```
This commit...

Changed functional behavior?
  yes -> Is it fixing an existing bug?
           yes -> fix
           no  -> feat
  no  -> Changed test files?
           yes -> test
           no  -> Changed docs / comments?
                  yes -> docs
                  no  -> Changed build / config / dependencies?
                         yes -> chore
                         no  -> Refactored code (no behavior change)?
                                yes -> refactor
                                no  -> Improved performance?
                                       yes -> perf
                                       no  -> chore (fallback)
```

---

## type Boundary Notes

### feat vs fix

```
feat: this feature did not exist before; now it is added
fix: this feature existed but behaved incorrectly; now it is fixed

When the boundary is blurry:
  "Added handling for an XXX edge case" -> fix (improving correctness of an existing feature)
  "Added a brand-new XXX command" -> feat
```

### refactor vs fix

```
refactor: external behavior is completely unchanged; only internal structure changed
fix: external behavior changed (even if the change is tiny)

Judgment method: do test cases need modification?
  No  -> refactor
  Yes -> fix or feat
```

### chore vs docs

```
docs: changes are to .md / comments / doc generation config
chore: changes are to Makefile / CI config / .gitignore / dependency versions

Mixed case: go with whichever has more changes, or split into two commits
```

---

## scope Naming Convention

scope source: the project module structure, not file names.

### aic project scopes

| scope | Corresponding module | Example files |
|-------|---------|----------|
| `install` | install command | cmd/aic/main.go (install branch)|
| `sync` | sync command | cmd/aic/main.go (sync branch)|
| `list` | list/browse TUI | internal/ui/list/ |
| `env` | environment variable management | internal/env/ |
| `config` | config read/write | internal/config/ |
| `registry` | GitLab repository operations | internal/registry/ |
| `linker` | symlink management | internal/linker/ |
| `parser` | SKILL.md parsing | internal/skill/parser.go |
| `ui` | TUI common components | internal/ui/ |

### Generic scopes (any project)

| scope | Purpose |
|-------|------|
| `api` | API interface layer |
| `db` | database related |
| `auth` | authentication and authorization |
| `config` | configuration management |

### When to omit scope

When the change spans multiple modules or is a global modification, scope can be omitted:

```
docs: update development plan, sync Phase 2 issue numbers
chore: upgrade all dependencies to latest versions
refactor: unify error handling approach
```

---

## Special Scenarios

### Merge / Squash commit

For branch merge commits, select the type matching the main content; the body can list included commits:

```
feat(install): complete all aic install command features

Includes:
- feat(parser): implement SKILL.md frontmatter parsing
- feat(registry): implement GitLab clone/pull
- feat(linker): implement symlink creation
- test(install): add install command integration tests

Closes #5, #6, #7, #8
```

### Revert commit

```
revert: feat(linker): implement symlink creation

Reason: introduced a race condition; temporarily reverting pending a fix.
Reverts commit abc1234.
Refs #15
```
