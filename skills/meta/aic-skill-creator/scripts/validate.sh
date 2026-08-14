#!/usr/bin/env bash
# validate.sh — validate SKILL.md structural compliance
# Usage: scripts/validate.sh <path/to/SKILL.md>
# Exit code: 0 = all checks passed, 1 = errors found

set -euo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <path/to/SKILL.md>" >&2
  exit 1
fi

if [[ ! -f "$TARGET" ]]; then
  echo "Error: file not found: $TARGET" >&2
  exit 1
fi

ERRORS=0
WARNINGS=0
SKILL_DIR="$(dirname "$TARGET")"
SKILL_DIR_NAME="$(basename "$SKILL_DIR")"

pass()  { echo "  ✓  $*"; }
warn()  { echo "  ⚠  $*"; WARNINGS=$((WARNINGS + 1)); }
fail()  { echo "  ✗  $*"; ERRORS=$((ERRORS + 1)); }

echo ""
echo "aic validate — $(realpath "$TARGET")"
echo "────────────────────────────────────────────────────────"

# ── 1. frontmatter existence check ───────────────────────
echo ""
echo "[1] Frontmatter structure"

# Check that the file starts with ---
if ! head -1 "$TARGET" | grep -q "^---"; then
  fail "SKILL.md must begin with YAML frontmatter (first line is ---)"
else
  pass "frontmatter opening present"
fi

# Extract frontmatter content (between the two --- lines)
FRONTMATTER="$(awk '/^---/{if(++c==2)exit} c==1{print}' "$TARGET")"

# ── 2. required fields check ─────────────────────────────
echo ""
echo "[2] Required fields"

# name
if ! echo "$FRONTMATTER" | grep -q "^name:"; then
  fail "Missing required field: name"
else
  FM_NAME="$(echo "$FRONTMATTER" | grep "^name:" | head -1 | sed 's/name:[[:space:]]*//')"
  pass "name: $FM_NAME"

  # name vs directory name consistency check
  if [[ "$FM_NAME" != "$SKILL_DIR_NAME" ]]; then
    fail "name field (${FM_NAME}) does not match directory name (${SKILL_DIR_NAME}); must match exactly"
  else
    pass "name matches directory name"
  fi
fi

# version
if ! echo "$FRONTMATTER" | grep -q "^version:"; then
  fail "Missing required field: version (aic enforces semantic versioning)"
else
  FM_VER="$(echo "$FRONTMATTER" | grep "^version:" | head -1 | sed 's/version:[[:space:]]*//')"
  # Simple semver format check MAJOR.MINOR.PATCH
  if echo "$FM_VER" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+$"; then
    pass "version: ${FM_VER} (valid format)"
  else
    fail "Invalid version format (expected MAJOR.MINOR.PATCH, got: ${FM_VER})"
  fi
fi

# description
if ! echo "$FRONTMATTER" | grep -q "^description:"; then
  fail "Missing required field: description"
else
  pass "description field present"
fi

# tags
if ! echo "$FRONTMATTER" | grep -q "^tags:"; then
  warn "Consider adding a tags field for easier filtering in aic list"
else
  pass "tags field present"
fi

# ── 3. env-required check ────────────────────────────────
echo ""
echo "[3] env-required rules"

ENV_REQUIRED="$(echo "$FRONTMATTER" | grep "^env-required:" | head -1 | sed 's/env-required:[[:space:]]*//')"
ENV_VAR_NAMES="$(echo "$FRONTMATTER" | sed -n 's/^[[:space:]]*-[[:space:]]*name:[[:space:]]*//p')"

if [[ -n "$ENV_VAR_NAMES" ]]; then
  while IFS= read -r var_name; do
    if echo "$var_name" | grep -qE '^[A-Z][A-Z0-9_]*$'; then
      pass "Variable name $var_name matches ^[A-Z][A-Z0-9_]*$"
    else
      fail "Variable name $var_name is invalid; must match ^[A-Z][A-Z0-9_]*$"
    fi
  done <<< "$ENV_VAR_NAMES"

  DUPLICATE_ENV_VARS="$(echo "$ENV_VAR_NAMES" | sort | uniq -d)"
  if [[ -n "$DUPLICATE_ENV_VARS" ]]; then
    fail "Duplicate variable names in env-vars: $(echo "$DUPLICATE_ENV_VARS" | tr '\n' ' ')"
  else
    pass "No duplicate variable names in env-vars"
  fi
fi

if [[ "$ENV_REQUIRED" == "true" ]]; then
  pass "env-required: true"

  # env-vars must be present
  if ! echo "$FRONTMATTER" | grep -q "^env-vars:"; then
    fail "When env-required: true, an env-vars list must be declared"
  else
    pass "env-vars field present"
  fi

  # Placeholders used in the body must be declared in env-vars
  BODY="$(awk 'BEGIN{found=0} /^---/{found++; next} found>=2{print}' "$TARGET")"
  PLACEHOLDERS="$(echo "$BODY" | grep -oE '\{\{[A-Z][A-Z0-9_]*\}\}' | sort -u || true)"
  if [[ -n "$PLACEHOLDERS" ]]; then
    while IFS= read -r ph; do
      VAR_NAME="${ph//[\{\}]/}"
      if echo "$ENV_VAR_NAMES" | grep -qx "$VAR_NAME"; then
        pass "Placeholder $ph is declared in env-vars"
      else
        fail "Placeholder $ph is used in the body but not declared in env-vars"
      fi
    done <<< "$PLACEHOLDERS"
  fi

  # Detect suspected hardcoded IPs or passwords
  BODY="$(awk 'BEGIN{found=0} /^---/{found++; next} found>=2{print}' "$TARGET")"
  if echo "$BODY" | grep -qE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"; then
    warn "Body appears to contain a hardcoded IP address; env-required skills should use {{VAR_NAME}} placeholders"
  fi
  if echo "$BODY" | grep -qiE "(password|passwd|secret|token)[[:space:]]*[:=][[:space:]]*[^{]"; then
    warn "Body appears to contain a hardcoded sensitive value; use {{VAR_NAME}} placeholders instead"
  fi

elif [[ "$ENV_REQUIRED" == "false" ]] || [[ -z "$ENV_REQUIRED" ]]; then
  pass "env-required: false (standard skill, no environment variables needed)"
else
  fail "Invalid env-required value (expected true or false, got: ${ENV_REQUIRED})"
fi

# ── 4. body length check ─────────────────────────────────
echo ""
echo "[4] Body length"

BODY_LINES="$(awk 'BEGIN{found=0} /^---/{found++; next} found>=2{print}' "$TARGET" | wc -l | tr -d ' ')"
if [[ "$BODY_LINES" -gt 500 ]]; then
  warn "Body is ${BODY_LINES} lines, exceeding the recommended 500-line limit. Consider moving detail into references/"
elif [[ "$BODY_LINES" -lt 10 ]]; then
  warn "Body is too short (${BODY_LINES} lines); skill instructions may be insufficient"
else
  pass "Body length ${BODY_LINES} lines (within reasonable range)"
fi

# ── 5. adapter layer check (informational) ───────────────
echo ""
echo "[5] Adapter layer (optional)"

for TOOL in claude codex gemini; do
  ADAPTER_PATH="$SKILL_DIR/adapters/$TOOL/SKILL.md"
  if [[ -f "$ADAPTER_PATH" ]]; then
    # Adapter layers also require complete frontmatter
    if ! head -1 "$ADAPTER_PATH" | grep -q "^---"; then
      fail "Adapter adapters/$TOOL/SKILL.md is missing frontmatter"
    else
      pass "adapters/$TOOL/SKILL.md exists and has frontmatter"
    fi
  fi
done

if [[ ! -d "$SKILL_DIR/adapters" ]]; then
  pass "No adapter layer (most skills do not need one)"
fi

# ── result summary ───────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────"
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo "✓  Validation passed, no errors, no warnings"
elif [[ $ERRORS -eq 0 ]]; then
  echo "⚠  Validation passed with ${WARNINGS} warning(s)"
else
  echo "✗  Validation failed: ${ERRORS} error(s), ${WARNINGS} warning(s)"
fi
echo ""

exit $ERRORS
