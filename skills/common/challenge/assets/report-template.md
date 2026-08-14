# Review Report Format Template

Copy this template and fill it in; do not improvise the structure.

---

```markdown
## challenge Review Report

**Review scope:** {filename:function} or {N files involved}
**Context source:** dev-plan (Task N.M: {Task title}) / README architecture section / no context
**Review language:** Go / Java / Python

---

### Phase 1: Logic Correctness

#### Consistent with Task intent / Intent deviation detected

(With dev-plan)
Task N.M states: {Task description}
- {declared action 1}: {code implementation status}
- {declared action 2}: {code implementation status; if not implemented, list as issue}

(Without dev-plan)
Intent inferred from code: {inferred function purpose}
- {boundary condition check conclusion}
- {error path check conclusion}
- {state consistency check conclusion}

---

### Phase 2: Security and Stability

#### P0 Critical (must fix; should not merge)

##### {Issue short title}

- **Location:** `internal/linker/linker.go:L45`
- **Risk type:** OOM / crash / data loss / injection / leak
- **Trigger condition:** triggered when {specific input/load/concurrency}
- **Code evidence:**
  ```go
  // problematic code (exact 3-5 lines, with line numbers)
  for _, item := range items {
      result = append(result, process(item))  // L45: unbounded growth
  }
  ```
- **Risk explanation:** when items exceeds X, under Y conditions, Z will happen
- **Fix direction:** add limit check at L43; return ErrTooManyItems when exceeded

---

#### P1 Needs Attention (should fix in this MR)

##### {Issue short title}

- **Location:** `internal/config/loader.go:L23`
- **Risk type:** boundary condition / error handling / state consistency
- **Trigger condition:** triggered when {specific condition}
- **Code evidence:**
  ```go
  // problematic code
  ```
- **Risk explanation:** {what specifically will happen}
- **Fix direction:** {specific action}

---

#### P2 Suggestions for Improvement (next PR)

##### {Issue short title}

- **Location:** `internal/config/project.go:L23`
- **Issue:** {one-sentence description}
- **Impact:** {when it will surface, what the consequence is}
- **Suggestion:** {improvement direction}

---

### Layer Conclusions

| Layer | Conclusion | Count |
|------|------|------|
| Phase 1 (Logic Correctness) | pass / deviation found | N |
| P0 (Critical) | none found / found | N |
| P1 (Needs Attention) | none found / found | N |
| P2 (Suggestions) | none found / found | N |

---

### Needs Manual Confirmation

- `internal/env/renderer.go:L67`: source of `config` variable unknown.
  If from user input, injection risk; if from internal config, safe.
  **Need to confirm:** where is config initialized, what is the source?
```
