# AI Coding Guideline

------

## 0. Local Tool Capabilities

**Prioritize command-line tools declared as available by the project; do not assume undeclared tools exist.**

This project declares the available command-line tools:

```text
{{ aic.env.AIC_AVAILABLE_CLI_TOOLS }}
```

When tasks involve repository status, commit history, branches, issues, MRs, or CI status, prioritize using the above tools for checks. For example, when the tool list includes `git`, use `git status`, `git diff`, `git log` to get local facts; when it includes `glab`, prioritize `glab` for querying GitLab issues, MRs, pipelines, or release info.

If a needed tool is not in the list, first state the missing tool and an alternative; do not fabricate command output.

------

## 1. Think Before Coding

**Do not assume; do not hide doubts; proactively expose tradeoffs.**

Before starting implementation, you must:

- **Clearly state your assumptions.** If unsure, ask directly; do not guess.
- **When multiple interpretations exist, list options for selection**; do not silently pick one.
- **When a simpler approach exists, say so proactively**; push back on requirements when necessary.
- **When anything is unclear, stop**, explain what is confusing, then ask.

> Typical mistake: the success criteria for "UDP probe" was undefined in the requirements; the AI chose ICMP and finished the code. Correct approach: stop and ask "What is the success criteria for a UDP probe? ICMP Echo, DNS response, or custom payload?"

------

## 2. Simplicity First

**Solve the problem with the least code; do not write speculative code.**

- Do not implement features beyond the requirements.
- Do not create abstraction layers or interfaces for code used only once.
- Do not add unrequested "flexibility" or "configurability."
- Do not write error handling for impossible scenarios (**exception**: in network programming, there are almost no "impossible" errors; connection drops, timeouts, and DNS failures must all be handled).

**Review after writing**: if you can clearly see a simpler approach in the existing implementation, proactively rewrite it; do not hand over redundant code. This is not a line-count limit but engineering discipline — if it can be simplified, do not keep the complex version.

Self-check standard: **"Would an experienced engineer consider this code over-engineered?"** If yes, simplify it.

------

## 3. Precise Modifications, Stay in Bounds

**Only touch what must be touched; only clean up messes you created.**

When modifying existing code:

- Do not "incidentally optimize" adjacent code, comments, or formatting.
- Do not refactor things that are not broken.
- Follow existing code style, even if you have different preferences.
- When you find unrelated dead code, **mention it but do not delete it** (unless explicitly asked).

When your changes produce orphaned code:

- Delete imports, variables, and functions that became unused **due to your changes**.
- Do not delete dead code that existed before your changes.

**Validation standard: every line of change in the diff should be directly traceable to the user request.**

------

## 4. Goal-Driven Execution

**Define verifiable success criteria; iterate until they pass.**

Transform vague tasks into verifiable goals:

| Vague statement | Transformed into verifiable goal |
| --------------- | ------------------------------------------------------------ |
| "Add validation" | "Write test cases for invalid input, then make the tests pass" |
| "Fix this bug" | "Write a test that reproduces the bug, then make it pass" |
| "Refactor X" | "Ensure test results are consistent before and after refactoring" |
| "Implement TCP probe" | "Write tests covering: connection success / port closed / timeout; then make them pass" |

For multi-step tasks, first output a brief plan:

```
1. [step] -> verification: [check item]
2. [step] -> verification: [check item]
3. [step] -> verification: [check item]
```

Clear success criteria let the AI iterate independently; vague criteria ("make it work") only lead to repeated confirmations.
