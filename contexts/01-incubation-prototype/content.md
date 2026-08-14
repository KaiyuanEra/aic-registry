# Project Context: Incubation and Prototype

## 1. Project Positioning

- The current goal is to validate the core hypothesis in the shortest path, not to build a complete production system.
- Before starting a task, clarify the problem to validate, the minimum success criteria, and what is out of scope.
- Prioritize delivering a runnable, observable minimal implementation; do not add complexity for hypothetical future needs.
- Exploratory code and temporary implementations are acceptable, but do not lower the security boundaries for keys, real data, and production environments.

## 2. Tech Stack and Architecture

- Verify the current tech stack from the target project existing memory files, README, dependency manifests, and build config; do not guess versions or modules.
- Preserve existing directory and call relationships; do not add architecture layers, generic frameworks, or extension points unless the validation goal clearly requires it.
- When technology selection is not yet stable, avoid irreversible data formats, public interfaces, and infrastructure bindings.
- Before adding a dependency, explain the problem it directly solves; do not introduce new dependencies when the standard library or existing dependencies suffice.

## 3. Common Commands

- Only run install, start, build, test, and lint commands already declared in the target project.
- Prioritize finding real commands from project memory files, README, Makefile, task scripts, and package manager config.
- When no reliable command is found, clearly state the gap; do not guess commands based on tech stack.
- For validation, first run the minimal command set covering core flows; avoid time-consuming work unrelated to the current hypothesis.

## 4. Code Conventions

- Use the simplest, most direct implementation; avoid premature abstraction, over-configuration, and one-off interfaces.
- Follow the target project existing style; do not use prototype tasks as an excuse to unify formatting or refactor unrelated code.
- Temporary implementations must have clear boundaries; do not disguise them as stable capabilities or spread them beyond core flows.
- Preserve necessary error handling for core validation paths so failure causes are observable and reproducible.

## 5. Prohibitions and High-Risk Operations

- Do not connect to production databases or call production services that produce real side effects.
- Do not commit .env files, keys, access tokens, passwords, or real user data.
- Do not execute releases, data cleanup, irreversible migrations, or other operations beyond the prototype validation scope.
- Do not bypass existing repository security restrictions and explicit prohibitions under the guise of "just a prototype."

## 6. Testing and Validation Flow

- Use whether the core hypothesis is verifiable and reproducible as the completion criterion; do not measure completion by code volume or file count.
- When the target project has tests, run tests directly related to the change; when there are no tests, execute and record reproducible manual validation steps.
- Cover at least the core success path and one failure path most likely to block validation.
- Report validation results, known limitations, and unexecuted checks on delivery; do not describe unknown results as success.

## 7. External Documentation References

- Prioritize reading product requirements, design drafts, and technical specs that already exist in the target project; extract only content relevant to the current validation goal.
- When referencing documents, use confirmed real paths or links; do not copy long content and do not create fabricated references.
