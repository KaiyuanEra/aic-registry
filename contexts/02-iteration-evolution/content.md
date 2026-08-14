# Project Context: Iteration and Business Evolution

## 1. Project Positioning

- The current goal is to deliver verifiable changes steadily and quickly while preserving existing architecture and business continuity.
- Before starting a task, clarify the business goal, impact scope, acceptance criteria, and items requiring manual decision.
- Implementation details within the requirement scope can be advanced autonomously; when involving public contracts, data semantics, release strategy, or cross-team boundaries, confirm first.
- Do not expand this iteration into unrelated architecture changes or global convention adjustments.

## 2. Tech Stack and Architecture

- Verify the tech stack and exact versions from the target project existing memory files, README, dependency manifests, and build config.
- Before modifying, locate core modules, callers, data flows, and test locations; follow current module boundaries.
- In a monorepo, prioritize reading the project description closest to the working directory and identify sub-package specific commands and constraints.
- When cross-module changes are needed, first explain interface changes and affected consumers; avoid drift from one-sided updates.
- Reference architecture details with real paths; do not copy implementation code or maintain a complete directory tree.

## 3. Common Commands

- Only use dependency install, local development, build, test, lint, and formatting commands already declared in the target project.
- Prioritize reusing the commands and parameters actually executed by CI to keep local validation consistent with merge gates.
- When no reliable command is found, report the gap; do not infer commands from framework names.
- First run checks directly related to the change, then expand to full validation per project requirements.

## 4. Code Conventions

- Follow the existing patterns of the target module; only record and enforce design conventions that linters and formatters cannot enforce.
- Place new features in existing modules with matching responsibilities; do not create generic abstractions without a real reuse need.
- Keep changes focused; delete orphaned code produced by this change; do not clean up pre-existing unrelated issues.
- Keep commits and review content traceable: every line of change should map to a business goal or necessary validation.
- When rules are detailed, reference stable documentation; avoid long-term memory bloat and duplication.

## 5. Prohibitions and High-Risk Operations

- Do not commit keys, access tokens, passwords, private certificates, or real sensitive data.
- Do not bypass CI, delete failing tests, or lower assertions to fabricate passing results.
- Without explicit authorization, do not modify high-risk boundaries such as database migrations, billing, permissions, releases, and infrastructure.
- Do not silently change public APIs, event structures, storage formats, or compatibility behavior.

## 6. Testing and Validation Flow

- New or modified logic must have validation proportional to the risk; automate regression as tests where possible.
- When fixing a defect, first establish reproducible conditions, then verify the fix covers the original problem and does not break adjacent behavior.
- For cross-module contract changes, verify both producer and consumer; for user flow changes, verify the complete main path.
- Before completion, run the tests, builds, and static checks required by the project; clearly report any unexecuted items and reasons.
- CI passing is only the minimum condition; also verify business acceptance criteria and change scope.

## 7. External Documentation References

- Prioritize reading detailed designs, API contracts, decision records, and collaboration conventions that already exist in the target project.
- Keep lengthy rules in their source documents; long-term memory records only reading context and real paths.
