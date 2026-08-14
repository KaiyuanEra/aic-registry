# Project Long-Term Memory Body Template

Use this template for a directly publishable general content.md. The responsibilities of the seven sections must be preserved, but do not fabricate project facts or TODOs to fill sections.

```markdown
# Project Context

## 1. Project Positioning

- State the goal and quality priorities for the current development stage.
- Clarify the scope the agent can handle autonomously and the high-risk boundaries that need confirmation.

## 2. Tech Stack and Architecture

- Verify the tech stack, entry points, and module boundaries from the target project existing docs and config first.
- Do not guess non-existent modules, versions, or directories.

## 3. Common Commands

- Use only build, test, lint, and startup commands already declared in the target project.
- When a command is not found, explain the gap; do not fabricate commands.

## 4. Code Conventions

- Follow the target project existing style; only supplement stage-specific principles that tools cannot automatically enforce.

## 5. Prohibitions and High-Risk Operations

- Write universally applicable, directly executable safety boundaries for the stage.

## 6. Testing and Validation Flow

- Define verifiable completion criteria based on the stage and report unexecuted validations.

## 7. External Documentation References

- Reference only documents confirmed to exist in the target project; do not copy long content.
```

## Deliverable Types

- General context: outputs cross-project stage behavior rules; does not require project-specific facts and contains no TODOs.
- Project-specific context: collects necessary facts before generation; the final file still contains no TODOs; when non-essential info is missing, omit it directly.
- Fill-in scaffold: TODOs are only allowed when the user explicitly requests "template", "placeholder", or "fill in later"; summarize them on delivery.

## Stage Adjustments

- Incubation: emphasize fast validation, minimal implementation, non-production boundaries, and avoiding premature freezing.
- Iteration: emphasize module boundaries, team collaboration, test validation, and controlling rule bloat.
- Maintenance: emphasize production safety, minimal changes, regression, release, and rollback.
- Refactor: emphasize old/new boundaries, behavior consistency, migration validation, and temporary rule expiry conditions.
