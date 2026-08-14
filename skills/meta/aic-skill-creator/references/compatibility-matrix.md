# Three-Tool Compatibility Matrix

> Quick reference for differences in skill loading mechanisms across Claude Code, Codex CLI, and Gemini CLI.
> Most skills only need the .agents/skills/ path; no adapter layer required.

---

## Path Quick Reference

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Shared project path** | .agents/skills/<name> | .agents/skills/<name> | .agents/skills/<name> |
| **Tool-specific path** | .claude/skills/<name> | — | .gemini/skills/<name> |
| **Global path** | ~/.claude/skills/ | ~/.codex/skills/ | ~/.gemini/skills/ |
| **Context file** | CLAUDE.md | AGENTS.md | GEMINI.md |

.agents/skills/ is the shared project path for all three tools; aic creates symlinks here by default.

---

## Frontmatter Field Compatibility

| Field | Claude Code | Codex CLI | Gemini CLI | aic requirement |
|------|-------------|-----------|------------|----------|
| name | optional | **required** | **required** | **required** |
| description | optional | **required** | **required** | **required** |
| version | not recognized | not recognized | not recognized | **required** (aic enforced) |
| tags | not recognized | not recognized | not recognized | recommended (aic list filter) |
| env-required | not recognized | not recognized | not recognized | as needed (aic rendering) |
| allowed-tools | **supported** | not supported | not supported | Claude adapter layer only |

**Conclusion:** Standard fields (name / description) are supported by all three tools. Proprietary fields like allowed-tools are only used in the corresponding tool adapter layer; writing them in the main SKILL.md will be ignored by other tools (harmless but adds redundancy).

---

## Trigger Mechanism Differences

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Trigger method** | LLM semantic match / /skill-name explicit call | description semantic match | activate_skill tool + user confirmation |
| **Routing** | pure LLM forward pass | description semantic match | Gemini autonomous decision + tool call |
| **Explicit call** | /skill-name | /skills or $skill | requires user confirmation |
| **Description preference** | leans toward not triggering; description needs to be slightly assertive | semantic match is sensitive | user confirms proactively; low false-trigger risk |

**Practical advice:**
- Write descriptions based on Claude Code as the baseline (needs slightly "proactive" descriptions)
- The same description typically works fine for Codex and Gemini

---

## When an Adapter Layer Is Needed

```
Conditions requiring an adapter layer (any one):
  - Claude Code needs allowed-tools to constrain tool permissions
  - A tool workflow differs substantively from others (not just wording)
  - Codex needs agents/openai.yaml for UI metadata

Cases not needing an adapter layer (the majority):
  - Only slight wording differences
  - Only minor description adjustments
  - Workflow is identical across all three tools
```

---

## Adapter Layer Directory Structure

```
skills/common/<skill-name>/
+-- SKILL.md                      <- shared by all three tools, placed in .agents/skills/
+-- adapters/
    +-- claude/
    |   +-- SKILL.md              <- placed in .claude/skills/ (includes allowed-tools)
    +-- codex/
    |   +-- SKILL.md
    |   +-- agents/openai.yaml    <- Codex UI metadata
    +-- gemini/
        +-- SKILL.md              <- placed in .gemini/skills/
```

When aic detects adapters/<tool>/, it automatically creates tool-specific path symlinks for that tool.

---

## Live Reload Support

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Edits take effect mid-session** | yes | needs restart | /memory reload |

When developing and debugging skills, use Claude Code for instant feedback — edits take effect immediately without restarting the tool.

---

## Compatibility Verification Checklist

Check before submitting a skill MR:

- [ ] Main SKILL.md name and description fields are filled (required by all three tools)
- [ ] version is filled (aic requires it)
- [ ] If allowed-tools exists, it is in adapters/claude/SKILL.md, not the main SKILL.md
- [ ] If agents/openai.yaml exists, it is in the adapters/codex/ directory
- [ ] Run scripts/self-test.sh <skill-name> to confirm all three tool paths are visible
