#!/usr/bin/env bash
# context-detect.sh — Detect git commit context information
# Usage: source scripts/context-detect.sh
#       or run directly and read the JSON output
#
# Output (JSON):
# {
#   "branch": "feature/issue-42-parser",
#   "issue_from_branch": 42,
#   "dev_plan_exists": true,
#   "matched_tasks": [
#     {"task_id": "2.2", "task_name": "Implement SKILL.md frontmatter parser", "issue": 42}
#   ],
#   "staged_files": ["internal/skill/parser.go", "internal/skill/model.go"],
#   "mode": "standard"   // standard | new-project | standalone
# }

set -euo pipefail

# ── Detect staged files ──────────────────────────────────────
STAGED_FILES="$(git diff --staged --name-only 2>/dev/null || echo "")"

if [[ -z "$STAGED_FILES" ]]; then
  cat <<'EOF'
{
  "error": "Staging area is empty; run git add on target files first",
  "staged_files": [],
  "mode": "error"
}
EOF
  exit 1
fi

# Convert to JSON array format
STAGED_JSON="$(echo "$STAGED_FILES" | python3 -c "
import sys, json
files = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps(files))
")"

# ── Detect git branch ────────────────────────────────────────
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"

# Extract Issue number from branch name (supports issue-42, #42, feature/42-xxx, etc.)
ISSUE_FROM_BRANCH="$(echo "$BRANCH" | grep -oE '(issue-|#|/)([0-9]+)' | grep -oE '[0-9]+' | head -1 || echo "")"

# ── Detect dev-plan.md ───────────────────────────────────────
DEV_PLAN_PATH="docs/dev-plan.md"
DEV_PLAN_EXISTS="false"
MATCHED_TASKS_JSON="[]"
MODE="standalone"

if [[ -f "$DEV_PLAN_PATH" ]]; then
  DEV_PLAN_EXISTS="true"

  # Check for existing Issue numbers (determine new vs. existing project)
  HAS_ISSUES="$(grep -c "Issue:.*#[0-9]" "$DEV_PLAN_PATH" 2>/dev/null || echo "0")"
  ALL_PENDING="$(grep -ci "Issue:.*#(pending)" "$DEV_PLAN_PATH" 2>/dev/null || echo "0")"

  if [[ "$HAS_ISSUES" -eq 0 ]] && [[ "$ALL_PENDING" -gt 0 ]]; then
    MODE="new-project"
  else
    MODE="standard"
  fi

  # Use Python for file-path cross-matching
  MATCHED_TASKS_JSON="$(python3 - "$DEV_PLAN_PATH" <<'PYEOF'
import sys
import re
import json

plan_path = sys.argv[1]

# Read staged file list (from environment variable)
import os
staged_raw = os.environ.get("STAGED_FILES", "")
staged = set(staged_raw.strip().splitlines())

tasks = []
current_task = None
current_files = []

with open(plan_path, encoding="utf-8") as f:
    for line in f:
        line = line.rstrip()

        # Match Task heading line
        m = re.match(r"#{1,6}\s+Task\s+([\d]+\.[\d]+)[:\s]+(.+)", line, re.IGNORECASE)
        if m:
            if current_task:
                tasks.append((current_task, current_files))
            current_task = {"id": m.group(1), "name": m.group(2).strip(), "issue": None, "files": []}
            current_files = []
            continue

        if current_task is None:
            continue

        # Extract files involved
        fm = re.search(r"\*\*Files involved:\*\*\s*(.+)", line, re.IGNORECASE)
        if fm:
            file_str = fm.group(1)
            # Extract backtick-enclosed paths
            files = re.findall(r"`([^`]+)`", file_str)
            current_task["files"] = files
            current_files = files

        # Extract Issue number
        im = re.search(r"\*\*Issue[:：]\*\*\s*#(\d+)", line)
        if im:
            current_task["issue"] = int(im.group(1))

        # On encountering the next heading, save current Task
        if re.match(r"^#{1,6}\s", line) and current_task and line not in ["", "---"]:
            if current_task.get("files") or current_task.get("issue"):
                pass  # continue

if current_task:
    tasks.append((current_task, current_files))

# Cross-match: changed files ∩ Task files involved
matched = []
for task, files in tasks:
    task_files = set(task.get("files", []))
    if task_files & staged:
        matched.append({
            "task_id": task["id"],
            "task_name": task["name"],
            "issue": task.get("issue"),
            "matching_files": list(task_files & staged)
        })

print(json.dumps(matched, ensure_ascii=False))
PYEOF
)" || MATCHED_TASKS_JSON="[]"

fi

# ── Assemble output JSON ─────────────────────────────────────
python3 - <<PYEOF
import json

result = {
    "branch": "$BRANCH",
    "issue_from_branch": $( [[ -n "$ISSUE_FROM_BRANCH" ]] && echo "$ISSUE_FROM_BRANCH" || echo "null" ),
    "dev_plan_exists": $DEV_PLAN_EXISTS,
    "matched_tasks": $MATCHED_TASKS_JSON,
    "staged_files": $STAGED_JSON,
    "mode": "$MODE"
}
print(json.dumps(result, ensure_ascii=False, indent=2))
PYEOF
