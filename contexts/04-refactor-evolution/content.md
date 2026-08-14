# Project Context: Refactor and Evolution

## 1. Project Positioning

- The current goal is to complete architecture migration while keeping business behavior verifiable; do not turn refactoring into unbounded rewriting.
- Before each change, first determine whether it belongs to old architecture maintenance, new architecture construction, or migration connection layer; when boundaries are unclear, confirm first.
- The old architecture focuses on necessary fixes and migration support; new features go into the clearly defined new architecture scope.
- Refactoring must not silently change business semantics; when changes are needed, treat them as independent requirements and validation targets.

## 2. Tech Stack and Architecture

- Verify old and new tech stacks and boundaries from the target project existing architecture docs, dependency manifests, and real directories.
- Establish old/new mappings for modules involved in the change; confirm callers, data flows, persistence, and release relationships.
- Migration status is based only on code, tests, traffic, or release facts; do not use subjective percentages or time estimates.
- When old and new implementations coexist, clarify the authoritative source and traffic entry point; avoid a third set of patterns that cannot be attributed.
- The migration connection layer stays thin and deletable; do not carry new long-term business logic.

## 3. Common Commands

- Use the old and new architecture build, test, and startup commands declared in the target project separately.
- Cross-boundary changes must execute both side validations and existing project consistency checks.
- Prioritize getting real commands from CI, migration scripts, and project docs; when not found, report the gap; do not guess.
- Before executing migration or cleanup commands, confirm input, scope, idempotency, and recovery method.

## 4. Code Conventions

- The old architecture follows existing conventions; only make necessary fixes; do not introduce new architecture patterns into old boundaries.
- The new architecture follows already-landed local patterns; do not replace existing facts with target architecture assumptions.
- Do not mix old and new dependency directions, data models, or error handling styles in the same module.
- Every temporary compatibility rule must carry a verifiable expiry condition; when the condition is met, delete the rule and code in the same phase.
- Refactoring commits stay small-step, reviewable, and rollbackable; business behavior changes and structural migrations are handled separately.

## 5. Prohibitions and High-Risk Operations

- Do not modify both old and new implementations of the same feature simultaneously when boundaries are unconfirmed.
- Do not delete old code, old data, or compatibility layers unless the replacement path is verified and no active callers exist.
- Do not perform one-shot migrations without a rollback plan; do not use manual data patches to cover up migration defects.
- Do not use refactoring to expand requirement scope, unify unrelated code styles, or replace untouched infrastructure.
- Do not commit keys, credentials, or real sensitive data.

## 6. Testing and Validation Flow

- First establish a pre-refactor behavior baseline, then prove that key inputs, outputs, and side effects remain consistent after refactoring.
- When modifying the old architecture, run old-side tests; when modifying the new architecture, run new-side tests; for cross-boundary changes, verify both sides.
- Use existing dual-write, replay, canary, or comparison mechanisms to verify consistency; when no mechanism exists, use reproducible equivalent validation.
- Before deleting old implementations, confirm that caller migration, data migration, monitoring, rollback, and release status all meet exit conditions.
- Completion criteria must be demonstrable by tests or runtime facts; code migration alone is not sufficient.

## 7. External Documentation References

- Prioritize reading migration plans, architecture decision records, and old/new comparison docs that already exist in the target project.
- Temporary conventions maintain expiry conditions in authoritative migration docs; long-term memory retains only stable boundaries and reading entry points.
