# Task Split Detailed Guide

## Granularity Principle

**Golden standard: one Task = 2-8 hours + 1-3 specific file changes**

| Scope | Action |
|------|------|
| < 2 hours | can merge into adjacent Task to reduce management overhead |
| 2-8 hours | ideal granularity |
| > 8 hours | must split further until the standard is met |

---

## Split Dimension Selection

Choose the split dimension by the following priority; use the first applicable one:

1. **File boundary** — work where changed files do not overlap; naturally isolated; split by this first
2. **Layer boundary** — data layer / business layer / interface layer separated; clear dependency direction
3. **Function boundary** — read operations / write operations / validation logic separated
4. **Stage boundary** — "basic implementation" and "error handling / edge cases" separated

---

## Task Field Filling Convention

### Task name (must be a verb phrase)

```
Good task names:
  Implement ParseSkill() function
  Add env-vars field validation
  Fix race condition in symlink creation

Bad task names:
  Parser module           <- noun; does not state what to do
  SKILL.md related work   <- unclear scope
  Optimize                <- no subject
```

### Files involved (must be specific paths)

```
Specific paths:
  internal/skill/parser.go
  internal/skill/model.go

Vague expressions:
  related Go files
  files under internal/skill/
```

### Input dependency

```
No prerequisite dependency:
  Input: no dependency (foundation module; can start independently)

Has prerequisite dependency:
  Input: can only start after Task 1.2 (config module) completes

Depends on external data:
  Input: GitLab API accessible; GITLAB_TOKEN configured
```

### Output deliverable (be specific to interface)

```
Specific deliverables:
  Output: ParseSkill(path string) (*Skill, error) function
  Output: GET /api/v4/skills/:name endpoint callable
  Output: validate.sh script outputs exit 0 for compliant SKILL.md

Vague deliverables:
  Output: feature implementation complete
  Output: code written
```

### Acceptance criteria (must be AI-self-verifiable)

```
Self-verifiable:
  go test ./internal/skill/... passes
  echo $? returns 0
  curl endpoint returns 200 and response body contains name field

Not self-verifiable:
  code logic is correct
  feature meets expectations (who judges?)
```

---

## Dependency Handling

Minimize strong dependencies between Tasks within the same Phase for parallel development:

```
Recommended:
  Task 1.1 and Task 1.2 both have no dependencies -> can start in parallel

Note:
  Task 1.3 depends on Task 1.1 -> state clearly in the "Input" field
  no need to draw a dependency graph; text description suffices
```

Cross-Phase dependencies: the next Phase defaults to depending on all of the previous Phase completing; no need to declare in each Task.

---

## Split Example (aic project)

**Original task (too large; needs splitting):**
> Implement aic install command

**Split result:**

```
Task 2.1: Implement .aicrc read/write
- Files involved: internal/config/project.go
- Input: no dependency
- Output: ReadAicrc() / WriteAicrc() functions
- Estimate: 3 hours

Task 2.2: Implement SKILL.md frontmatter parsing
- Files involved: internal/skill/parser.go, internal/skill/model.go
- Input: no dependency
- Output: ParseSkill(path string) (*Skill, error)
- Estimate: 3 hours

Task 2.3: Implement GitLab repository clone/pull
- Files involved: internal/registry/client.go
- Input: Task 2.1 completed (needs registry_url config)
- Output: FetchRegistry(branch string) error
- Estimate: 4 hours

Task 2.4: Implement symlink creation logic
- Files involved: internal/linker/linker.go, internal/linker/paths.go
- Input: Task 2.2 completed (needs parsed Skill struct)
- Output: LinkSkill(skill *Skill, tools []string) error
- Estimate: 4 hours

Task 2.5: Assemble aic install command entry
- Files involved: cmd/aic/main.go
- Input: Task 2.1 / 2.2 / 2.3 / 2.4 all completed
- Output: aic install <name>[@version] executable
- Estimate: 2 hours
```
