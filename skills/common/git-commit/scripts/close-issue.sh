#!/usr/bin/env bash
# close-issue.sh — 通过 GitLab/GitHub API 关闭 Issue，并更新 dev-plan.md 状态
#
# 用法：
#   bash scripts/close-issue.sh <issue_number> [--dry-run]
#
# 依赖环境变量（从 ~/.aic-env 或 shell 环境读取）：
#   GITLAB_TOKEN   GitLab personal access token（优先）
#   GITHUB_TOKEN   GitHub personal access token
#
# 自动推断平台和项目：
#   - 从 git remote origin URL 解析 host / namespace / repo
#   - GitLab: host 非 github.com 时使用
#   - GitHub:  host 为 github.com 时使用
#
# 退出码：
#   0  成功关闭（或 dry-run 预览）
#   1  参数错误 / 缺少 token / API 失败

set -euo pipefail

ISSUE_NUMBER="${1:-}"
DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

# ── 参数校验 ──────────────────────────────────────────────────
if [[ -z "$ISSUE_NUMBER" ]] || ! [[ "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "用法：bash scripts/close-issue.sh <issue_number> [--dry-run]" >&2
  exit 1
fi

# ── 从 ~/.aic-env 补充环境变量（若 aic 未注入则手动读取）────────
AIC_ENV_FILE="${HOME}/.aic-env"
if [[ -f "$AIC_ENV_FILE" ]]; then
  # 只导入 GITLAB_TOKEN / GITHUB_TOKEN，不污染其他变量
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^(GITLAB_TOKEN|GITHUB_TOKEN)$ ]] || continue
    [[ -z "${!key:-}" ]] && export "$key"="$value"
  done < <(grep -E '^(GITLAB_TOKEN|GITHUB_TOKEN)=' "$AIC_ENV_FILE" 2>/dev/null || true)
fi

# ── 解析 remote URL ───────────────────────────────────────────
REMOTE_URL="$(git remote get-url origin 2>/dev/null || echo "")"
if [[ -z "$REMOTE_URL" ]]; then
  echo "错误：无法获取 git remote origin URL" >&2
  exit 1
fi

# 支持 SSH（git@host:ns/repo.git）和 HTTPS（https://host/ns/repo.git）
if [[ "$REMOTE_URL" =~ ^git@([^:]+):(.+)/([^/]+)\.git$ ]]; then
  HOST="${BASH_REMATCH[1]}"
  NAMESPACE="${BASH_REMATCH[2]}"
  REPO="${BASH_REMATCH[3]}"
elif [[ "$REMOTE_URL" =~ ^https?://([^/]+)/(.+)/([^/]+)(\.git)?$ ]]; then
  HOST="${BASH_REMATCH[1]}"
  NAMESPACE="${BASH_REMATCH[2]}"
  REPO="${BASH_REMATCH[3]}"
else
  echo "错误：无法解析 remote URL：$REMOTE_URL" >&2
  exit 1
fi

# ── 判断平台 ──────────────────────────────────────────────────
if [[ "$HOST" == "github.com" ]]; then
  PLATFORM="github"
  API_URL="https://api.github.com/repos/${NAMESPACE}/${REPO}/issues/${ISSUE_NUMBER}"
  PAYLOAD='{"state":"closed"}'
  HTTP_METHOD="PATCH"
else
  PLATFORM="gitlab"
  ENCODED_PATH="$(python3 -c "import urllib.parse; print(urllib.parse.quote('${NAMESPACE}/${REPO}', safe=''))")"
  API_URL="https://${HOST}/api/v4/projects/${ENCODED_PATH}/issues/${ISSUE_NUMBER}"
  PAYLOAD='{"state_event":"close"}'
  HTTP_METHOD="PUT"
fi

# ── Dry-run 预览（不需要 token）────────────────────────────────
if $DRY_RUN; then
  echo "[dry-run] 平台：$PLATFORM"
  echo "[dry-run] 项目：${NAMESPACE}/${REPO}"
  echo "[dry-run] API：${HTTP_METHOD} $API_URL"
  echo "[dry-run] 将关闭 Issue #${ISSUE_NUMBER}"
  exit 0
fi

# ── Token 校验（仅实际调用时需要）────────────────────────────
if [[ "$PLATFORM" == "github" ]]; then
  TOKEN="${GITHUB_TOKEN:-}"
  if [[ -z "$TOKEN" ]]; then
    echo "⚠️  跳过关闭 Issue：未找到 GITHUB_TOKEN（可通过 aic env add 配置，或安装 glab-manage skill）" >&2
    exit 0
  fi
  AUTH_HEADER="Authorization: Bearer ${TOKEN}"
else
  TOKEN="${GITLAB_TOKEN:-}"
  if [[ -z "$TOKEN" ]]; then
    echo "⚠️  跳过关闭 Issue：未找到 GITLAB_TOKEN（可通过 aic env add 配置，或安装 glab-manage skill）" >&2
    exit 0
  fi
  AUTH_HEADER="PRIVATE-TOKEN: ${TOKEN}"
fi

# ── 调用 API ──────────────────────────────────────────────────
HTTP_CODE="$(curl -s -o /tmp/close_issue_resp.json -w "%{http_code}" \
  -X "$HTTP_METHOD" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d "$PAYLOAD" \
  "$API_URL")"

if [[ "$HTTP_CODE" =~ ^2 ]]; then
  echo "Issue #${ISSUE_NUMBER} 已关闭（$PLATFORM）"
else
  echo "错误：API 返回 HTTP $HTTP_CODE" >&2
  cat /tmp/close_issue_resp.json >&2
  exit 1
fi

# ── 更新 dev-plan.md ──────────────────────────────────────────
DEV_PLAN_PATH="docs/dev-plan.md"
if [[ ! -f "$DEV_PLAN_PATH" ]]; then
  exit 0
fi

# 将 dev-plan.md 中对应 Issue 行的状态标记为已完成
# 匹配格式：| 进行中 | 或 **状态**: 进行中 → 替换为已完成
python3 - "$DEV_PLAN_PATH" "$ISSUE_NUMBER" <<'PYEOF'
import sys
import re

plan_path = sys.argv[1]
issue_num = sys.argv[2]

with open(plan_path, encoding="utf-8") as f:
    content = f.read()

issue_pattern = re.compile(r"Issue[^#\n]*#" + re.escape(issue_num) + r"\b")
heading_pattern = re.compile(r"^#{1,6}\s", re.MULTILINE)

# 切分成块；若无标题则整个文件作为一块
headings = [m.start() for m in heading_pattern.finditer(content)]
if not headings:
    headings = [0]
headings.append(len(content))

def replace_status(block):
    # 匹配 **状态:** / **状态**: / 状态: 等各种格式
    b = re.sub(r"(\*{0,2}状态\*{0,2}[:：]\*{0,2}\s*)(进行中)", r"\1已完成", block)
    # 表格行格式：| 进行中 |
    b = re.sub(r"(\|\s*)(进行中)(\s*\|)", r"\1已完成\3", b)
    return b

updated = content
for i in range(len(headings) - 1):
    block = content[headings[i]:headings[i+1]]
    if issue_pattern.search(block):
        new_block = replace_status(block)
        if new_block != block:
            updated = updated[:headings[i]] + new_block + updated[headings[i+1]:]
            break

if updated != content:
    with open(plan_path, "w", encoding="utf-8") as f:
        f.write(updated)
    print(f"dev-plan.md 已更新：Issue #{issue_num} 状态 → 已完成")
else:
    print(f"dev-plan.md 未找到可更新的 Issue #{issue_num} 状态行（可能已是最新）")
PYEOF
