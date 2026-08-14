# Project Context: Maintenance and Stable Operation

## 1. Project Positioning

- The current goal is to keep the live system stable, recoverable, and behavior-compatible; risk control takes priority over delivery speed.
- Before modifying, first explain impact scope, potential regressions, validation methods, and recovery plans before handling high-risk changes.
- Prioritize minimal and rollbackable fixes; do not use maintenance tasks as an excuse to upgrade dependencies, refactor architecture, or change unrelated behavior.
- When involving production data, releases, permissions, billing, or external service side effects, obtain explicit authorization first.

## 2. Tech Stack and Architecture

- Verify the production tech stack from the target project actual deployment config, lock files, and runtime docs; do not use outdated descriptions.
- Before modifying, locate entry points, upstream/downstream calls, persistence boundaries, external dependencies, and existing protection mechanisms.
- For external system calls, clarify timeout, retry, idempotency, and failure impact; do not treat network success as business success.
- Keep public interfaces, data formats, and storage semantics backward-compatible; when compatibility must break, first create a migration and rollback plan.

## 3. Common Commands

- Only use reproduction, regression, build, release check, and rollback commands already declared in the target project.
- Prioritize getting commands from runbooks, CI config, Makefiles, and controlled scripts; do not assemble production operations from experience.
- Default to read-only diagnostics first; confirm target, scope, and recovery method for any write operation.
- When no reliable command or process is found, stop and report the gap; do not trial-and-error in production-related scenarios.

## 4. Code Conventions

- Keep the modification scope minimal; follow existing stable patterns; do not perform unrelated renaming, formatting, or abstraction adjustments.
- Error handling must preserve cause and context; do not swallow errors that would affect alerting, retry, or rollback decisions.
- When changing config, defaults, caching, concurrency, or retry behavior, clearly state the runtime impact.
- When adding compatibility branches, write the removal condition; avoid permanent accumulation of temporary fixes.

## 5. Prohibitions and High-Risk Operations

- Do not directly operate on production databases; do not execute unreviewed migrations, fix SQL, or data cleanup.
- Do not bypass approvals, release gates, canary processes, or audit requirements to change production directly.
- Do not read, output, or commit keys, credentials, private certificates, or real user sensitive data.
- Before modifying migrations, payment/billing, identity/permissions, deployment, and CI/CD config, first explain the impact and wait for confirmation.
- During incidents, first control impact, preserve evidence, and follow existing emergency procedures; do not execute consecutive irreversible operations.

## 6. Testing and Validation Flow

- Defect fixes must cover reproduction cases, fix results, and key adjacent regressions.
- Run full regression, builds, and static checks per project requirements; when unable to execute, clearly state the risk; do not claim validation is complete.
- Before release, verify canary, monitoring, alerting, and rollback conditions; after release, verify key business metrics and error rates.
- During incident response, prioritize restoring service, then locate root cause with complete evidence.
- Completion criteria include both functional correctness, no known regressions, observability, and recoverability.

## 7. External Documentation References

- Prioritize reading release runbooks, rollback manuals, monitoring docs, and incident postmortems that already exist in the target project.
- For high-risk operations, only reference authoritative procedures; do not copy potentially outdated operation steps into long-term memory.
