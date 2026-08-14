# glab CLI Fallback

> Used when GITLAB_TOKEN is not configured but glab is available on the system.
> glab requires prior `glab auth login` for authentication.

---

## Check if glab Is Available

```bash
if command -v glab &>/dev/null && glab auth status &>/dev/null 2>&1; then
  echo "glab available, using CLI mode"
else
  echo "glab not available; configure GITLAB_TOKEN or install glab"
fi
```

---

## Common glab Commands

### Milestone (glab does not yet support direct milestone management)

glab CLI currently does not support milestone creation and management; this scenario must fall back to the Web API.

---

### Issue Operations

```bash
# Create issue
glab issue create \
  --title "[Phase 1] Implement SKILL.md frontmatter parsing" \
  --description "## Task Objective
Parse the YAML header of SKILL.md..." \
  --label "phase-1,feat" \
  --milestone "Phase 1: Core Foundation Modules"

# List issues
glab issue list --state opened

# Close issue
glab issue close 42
```

---

## glab Installation

```bash
# macOS
brew install glab

# Linux (via package manager)
sudo apt install glab        # Debian/Ubuntu
sudo dnf install glab        # Fedora

# Generic (download binary)
# Visit https://gitlab.com/gitlab-org/cli/-/releases for the latest version
```

---

## Authentication Configuration

```bash
# Configure internal GitLab
glab auth login --hostname git.ifogging.cn

# Verify auth status
glab auth status
```

---

## Fallback Limitations

| Feature | Web API | glab CLI |
|------|---------|----------|
| Create milestone | yes | no (use API) |
| Create issue | yes | yes |
| Link issue to milestone | yes | partial (via --milestone name; must already exist) |
| Batch creation | yes | yes (loop calls) |
| Get issue iid for writeback | yes | yes (parse glab output) |

**Conclusion:** Milestone creation requires the Web API. glab is only suitable for issue-only creation scenarios.
