#!/usr/bin/env bash
#  description-score.sh — score description trigger quality
# Usage: scripts/description-score.sh <path/to/SKILL.md>
# Output: 0–100 score with detailed improvement suggestions
# Exit code: 0 = score >= 60, 1 = score < 60 (rewrite recommended)

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

# Extract the description field content (supports multi-line YAML block scalars)
FRONTMATTER="$(awk '/^---/{if(++c==2)exit} c==1{print}' "$TARGET")"
DESCRIPTION="$(echo "$FRONTMATTER" | awk '/^description:/{found=1; sub(/^description:[[:space:]]*(>)?[[:space:]]*/,""); if($0!="")print; next} found && /^[[:space:]]/{print; next} found && /^[^[:space:]]/{exit}' | sed 's/^[[:space:]]*//')"

if [[ -z "$DESCRIPTION" ]]; then
  echo ""
  echo "Error: no description field content found" >&2
  exit 1
fi

SCORE=0
DETAIL=()

echo ""
echo "aic description-score — $(realpath "$TARGET")"
echo "────────────────────────────────────────────────────────"
echo ""
echo "Description content:"
echo "$DESCRIPTION" | sed 's/^/  /'
echo ""
echo "────────────────────────────────────────────────────────"
echo "Score breakdown:"
echo ""

# ── Check 1: starts with a verb or functional noun (20 pts) ──────────
FIRST_WORD="$(echo "$DESCRIPTION" | head -1 | awk '{print $1}')"
WEAK_VERBS="(Help|Helps|Assist|Assists|Handle|Handles|Deal|A |An |The |This)"
if echo "$FIRST_WORD" | grep -qiE "^($WEAK_VERBS)"; then
  DETAIL+=("  ✗  [-0 ] Weak opening verb (\"$FIRST_WORD\"); use a clear action verb (execute/generate/analyze/manage)")
else
  SCORE=$((SCORE + 20))
  DETAIL+=("  ✓  [+20] Starts with an effective verb or functional noun")
fi

# ── Check 2: contains a "Use when" trigger scenario (25 pts) ─────────
if echo "$DESCRIPTION" | grep -qi "use when"; then
  SCORE=$((SCORE + 30))
  DETAIL+=("  ✓  [+30] Contains a 'Use when' trigger scenario")
else
  DETAIL+=("  ✗  [-0 ] Missing a 'Use when' section — the agent does not know when to trigger this skill")
fi

# ── Check 3: contains a "Do NOT use for" exclusion boundary (20 pts) ─
if echo "$DESCRIPTION" | grep -qi "do not use\|don't use\|DO NOT USE\|DO NOT USE FOR"; then
  SCORE=$((SCORE + 25))
  DETAIL+=("  ✓  [+25] Contains an exclusion boundary (Do NOT use for)")
else
  DETAIL+=("  ✗  [-0 ] Missing a 'Do NOT use for' section — may collide with adjacent skills and mis-trigger")
fi

# ── Check 4: language coverage hint (info, no points) ────────────────
# Scoring checks structural completeness only, not language; Chinese and
# English descriptions are evaluated on the same scale.
HAS_ZH=false
if echo "$DESCRIPTION" | grep -qP "[\x{4e00}-\x{9fff}]" 2>/dev/null || \
   echo "$DESCRIPTION" | grep -q "[一-龿]"; then
  HAS_ZH=true
fi
HAS_EN=false
if echo "$DESCRIPTION" | grep -qE "[a-zA-Z]{2,}"; then
  HAS_EN=true
fi
if [[ "$HAS_ZH" == true ]]; then
  DETAIL+=("  ℹ  [ 0 ] Contains Chinese keywords, helpful for triggering on Chinese prompts (info, no points)")
elif [[ "$HAS_EN" == true ]]; then
  DETAIL+=("  ℹ  [ 0 ] Contains English trigger words, helpful for triggering on English prompts (info, no points)")
else
  DETAIL+=("  ⚠  [ 0 ] No clear trigger words detected; add trigger words in the 'Use when' section")
fi

# ── Check 5: reasonable description length (10 pts) ──────────────────
WORD_COUNT="$(echo "$DESCRIPTION" | wc -w | tr -d ' ')"
if [[ "$WORD_COUNT" -lt 10 ]]; then
  DETAIL+=("  ✗  [-0 ] Description too short (${WORD_COUNT} words); covers too few scenarios and will rarely trigger")
elif [[ "$WORD_COUNT" -gt 200 ]]; then
  DETAIL+=("  ⚠  [-0 ] Description too long (${WORD_COUNT} words); over 150 words suggests the skill scope is too broad")
  SCORE=$((SCORE + 5))
else
  SCORE=$((SCORE + 10))
  DETAIL+=("  ✓  [+10] Reasonable description length (${WORD_COUNT} words)")
fi

# ── Check 6: contains concrete scenario keywords (10 pts) ────────────
SCENARIO_PATTERNS="(when|mention|says|asks about|need|mention|Encounter)"
SCENARIO_COUNT="$(echo "$DESCRIPTION" | grep -ciE "$SCENARIO_PATTERNS" || true)"
if [[ "$SCENARIO_COUNT" -ge 2 ]]; then
  SCORE=$((SCORE + 15))
  DETAIL+=("  ✓  [+15] Contains ${SCENARIO_COUNT} concrete scenario keywords")
elif [[ "$SCENARIO_COUNT" -eq 1 ]]; then
  SCORE=$((SCORE + 8))
  DETAIL+=("  ⚠  [+8 ] Only 1 scenario keyword; consider adding more trigger scenarios")
else
  DETAIL+=("  ✗  [-0 ] Missing concrete scenario descriptions; trigger rate will be low")
fi

# ── Output breakdown ─────────────────────────────────────────────────
for line in "${DETAIL[@]}"; do
  echo "$line"
done

echo ""
echo "────────────────────────────────────────────────────────"
printf "Total score: %d / 100\n" "$SCORE"

if [[ "$SCORE" -ge 80 ]]; then
  echo "Rating: Excellent ✓  description quality is good, ready to submit"
elif [[ "$SCORE" -ge 60 ]]; then
  echo "Rating: Pass ⚠  consider refining per references/description-patterns.md"
else
  echo "Rating: Fail ✗  rewrite the description; see references/description-patterns.md"
fi

echo ""
echo "Reference: skills/aic-skill-creator/references/description-patterns.md"
echo ""

if [[ "$SCORE" -lt 60 ]]; then
  exit 1
fi
exit 0
