#!/usr/bin/env bash
# context-detect.sh — 检测 git commit 的上下文信息
# 用法：source scripts/context-detect.sh
#       或直接执行后读取输出 JSON
#
# 输出（JSON）：
# {
#   "branch": "feature/issue-42-parser",
#   "issue_from_branch": 42,
#   "dev_plan_exists": true,
#   "matched_tasks": [
#     {"task_id": "2.2", "task_name": "实现 SKILL.md frontmatter 解析", "issue": 42}
#   ],
#   "staged_files": ["internal/skill/parser.go", "internal/skill/model.go"],
#   "mode": "standard"   // standard | new-project | standalone
# }

set -euo pipefail

# ── 检测暂存区文件 ─────────────────────────────────────────
STAGED_FILES="$(git diff --staged --name-only 2>/dev/null || echo "")"

if [[ -z "$STAGED_FILES" ]]; then
  cat <<'EOF'
{
  "error": "暂存区为空，请先 git add 目标文件",
  "staged_files": [],
  "mode": "error"
}
EOF
  exit 1
fi

# 转为 JSON 数组格式
STAGED_JSON="$(echo "$STAGED_FILES" | python3 -c "
import sys, json
files = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps(files))
")"

# ── 检测 git branch ────────────────────────────────────────
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"

# 从分支名提取 Issue 编号（支持 issue-42、#42、feature/42-xxx 等格式）
ISSUE_FROM_BRANCH="$(echo "$BRANCH" | grep -oE '(issue-|#|/)([0-9]+)' | grep -oE '[0-9]+' | head -1 || echo "")"

# ── 检测 dev-plan.md ────────────────────────────────────────
DEV_PLAN_PATH="docs/dev-plan.md"
DEV_PLAN_EXISTS="false"
MATCHED_TASKS_JSON="[]"
MODE="standalone"

if [[ -f "$DEV_PLAN_PATH" ]]; then
  DEV_PLAN_EXISTS="true"

  # 检查是否有已有 Issue 编号（判断新老项目）
  HAS_ISSUES="$(grep -c "Issue:.*#[0-9]" "$DEV_PLAN_PATH" 2>/dev/null || echo "0")"
  ALL_PENDING="$(grep -c "Issue:.*#（待创建）" "$DEV_PLAN_PATH" 2>/dev/null || echo "0")"

  if [[ "$HAS_ISSUES" -eq 0 ]] && [[ "$ALL_PENDING" -gt 0 ]]; then
    MODE="new-project"
  else
    MODE="standard"
  fi

  # 用 Python 做文件路径交叉匹配
  MATCHED_TASKS_JSON="$(python3 - "$DEV_PLAN_PATH" <<'PYEOF'
import sys
import re
import json

plan_path = sys.argv[1]

# 读取暂存文件列表（从环境变量）
import os
staged_raw = os.environ.get("STAGED_FILES", "")
staged = set(staged_raw.strip().splitlines())

tasks = []
current_task = None
current_files = []

with open(plan_path, encoding="utf-8") as f:
    for line in f:
        line = line.rstrip()

        # 匹配 Task 标题行
        m = re.match(r"#{1,6}\s+Task\s+([\d]+\.[\d]+)[:\s]+(.+)", line, re.IGNORECASE)
        if m:
            if current_task:
                tasks.append((current_task, current_files))
            current_task = {"id": m.group(1), "name": m.group(2).strip(), "issue": None, "files": []}
            current_files = []
            continue

        if current_task is None:
            continue

        # 提取涉及文件
        fm = re.search(r"\*\*涉及文件[:：]\*\*\s*(.+)", line)
        if fm:
            file_str = fm.group(1)
            # 提取反引号内的路径
            files = re.findall(r"`([^`]+)`", file_str)
            current_task["files"] = files
            current_files = files

        # 提取 Issue 编号
        im = re.search(r"\*\*Issue[:：]\*\*\s*#(\d+)", line)
        if im:
            current_task["issue"] = int(im.group(1))

        # 遇到下一个标题行，保存当前 Task
        if re.match(r"^#{1,6}\s", line) and current_task and line not in ["", "---"]:
            if current_task.get("files") or current_task.get("issue"):
                pass  # 继续

if current_task:
    tasks.append((current_task, current_files))

# 交叉匹配：变更文件 ∩ Task 涉及文件
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

# ── 组装输出 JSON ──────────────────────────────────────────
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
