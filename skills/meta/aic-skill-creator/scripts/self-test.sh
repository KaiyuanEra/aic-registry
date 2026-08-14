#!/usr/bin/env bash
# self-test.sh — verify a skill is visible across the three AI tools
# Usage: scripts/self-test.sh <skill-name> [project-root]
# Note: run inside a project directory that has run `aic install`
#       project-root defaults to the current directory

set -euo pipefail

SKILL_NAME="${1:-}"
PROJECT_ROOT="${2:-$(pwd)}"

if [[ -z "$SKILL_NAME" ]]; then
  echo "Usage: $0 <skill-name> [project-root]" >&2
  echo "Example: $0 database-ops /path/to/my-project" >&2
  exit 1
fi

echo ""
echo "aic self-test — skill: $SKILL_NAME"
echo "project: $PROJECT_ROOT"
echo "────────────────────────────────────────────────────────"

ERRORS=0

check_link() {
  local TOOL_NAME="$1"
  local LINK_PATH="$2"
  local REQUIRED="$3"   # "required" or "optional"

  if [[ -L "$LINK_PATH" ]]; then
    TARGET_PATH="$(readlink "$LINK_PATH")"
    if [[ -e "$LINK_PATH" ]]; then
      echo "  ✓  $TOOL_NAME  →  $LINK_PATH"
      echo "             → $(readlink -f "$LINK_PATH" 2>/dev/null || echo "$TARGET_PATH")"
      # Check whether SKILL.md exists at the link target
      if [[ -f "$LINK_PATH/SKILL.md" ]]; then
        echo "             SKILL.md readable ✓"
      else
        echo "             ⚠  SKILL.md does not exist at the link target"
        ERRORS=$((ERRORS + 1))
      fi
    else
      echo "  ✗  $TOOL_NAME  →  $LINK_PATH (broken link, target does not exist: $TARGET_PATH)"
      ERRORS=$((ERRORS + 1))
    fi
  elif [[ -d "$LINK_PATH" ]]; then
    echo "  ⚠  $TOOL_NAME  →  $LINK_PATH (directory exists but is not a symlink; may have been created manually)"
  else
    if [[ "$REQUIRED" == "required" ]]; then
      echo "  ✗  $TOOL_NAME  →  $LINK_PATH (does not exist)"
      ERRORS=$((ERRORS + 1))
    else
      echo "  –  $TOOL_NAME  →  $LINK_PATH (does not exist; tool not installed or no adapter layer)"
    fi
  fi
}

echo ""
echo "[1] Shared path (read by all three tools)"
SHARED_PATH="$PROJECT_ROOT/.agents/skills/$SKILL_NAME"
check_link "Claude / Codex / Gemini  .agents" "$SHARED_PATH" "required"

echo ""
echo "[2] Claude Code specific path (used when an adapter layer exists)"
CLAUDE_PATH="$PROJECT_ROOT/.claude/skills/$SKILL_NAME"
check_link "Claude Code  .claude" "$CLAUDE_PATH" "optional"

echo ""
echo "[3] Gemini CLI specific path (used when an adapter layer exists)"
GEMINI_PATH="$PROJECT_ROOT/.gemini/skills/$SKILL_NAME"
check_link "Gemini CLI   .gemini" "$GEMINI_PATH" "optional"

echo ""
echo "[4] Codex CLI path notes"
echo "  –  Codex CLI has no specific path; it uses .agents/skills/ uniformly (see [1] above)"

# ── .aicrc declaration check ────────────────────────────
echo ""
echo "[5] .aicrc declaration"
AICRC_PATH="$PROJECT_ROOT/.aicrc"
if [[ -f "$AICRC_PATH" ]]; then
  if grep -q "name.*=.*\"$SKILL_NAME\"" "$AICRC_PATH" || \
     grep -q "name.*=.*'$SKILL_NAME'" "$AICRC_PATH"; then
    echo "  ✓  $SKILL_NAME is declared in .aicrc"
    # Check the version
    VERSION_LINE="$(grep -A5 "name.*=.*[\"']$SKILL_NAME[\"']" "$AICRC_PATH" | grep "version" | head -1 || true)"
    if [[ -n "$VERSION_LINE" ]]; then
      echo "     $VERSION_LINE"
    fi
    # Check env_required
    ENV_LINE="$(grep -A5 "name.*=.*[\"']$SKILL_NAME[\"']" "$AICRC_PATH" | grep "env_required" | head -1 || true)"
    if [[ -n "$ENV_LINE" ]]; then
      echo "     $ENV_LINE"
    fi
  else
    echo "  ✗  $SKILL_NAME is not declared in .aicrc (run aic install $SKILL_NAME first)"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  ⚠  .aicrc does not exist in $PROJECT_ROOT (run aic init first)"
fi

# ── result summary ───────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────"
if [[ $ERRORS -eq 0 ]]; then
  echo "✓  $SKILL_NAME can be read by AI tools in the current project"
else
  echo "✗  Found ${ERRORS} issue(s); fix them and re-run"
  echo ""
  echo "Common fix commands:"
  echo "  aic init                  # initialize the project directory structure"
  echo "  aic install $SKILL_NAME   # install the skill and create links"
  echo "  aic sync                  # repair broken links"
fi
echo ""

exit $ERRORS
