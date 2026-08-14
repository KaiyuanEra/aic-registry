#!/usr/bin/env bash
# close-issue.sh — Close an Issue via GitLab/GitHub API and update dev-plan.md status
#
# Usage:
#   bash scripts/close-issue.sh <issue_number> [--dry-run]
#
# Required environment variables (read from ~/.aic-env or shell env):
#   GITLAB_TOKEN   GitLab personal access token (preferred)
#   GITHUB_TOKEN   GitHub personal access token
#
# Auto-detects platform and project:
#   - Parses host / namespace / repo from git remote origin URL
#   - GitLab: used when host is not github.com
#   - GitHub:  used when host is github.com
#
# Exit codes:
#   0  Successfully closed (or dry-run preview)
#   1  Argument error / missing token / API failure

set -euo pipefail

ISSUE_NUMBER="${1:-}"
DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

# ── Argument validation ───────────────────────────────────────
if [[ -z "$ISSUE_NUMBER" ]] || ! [[ "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Usage: bash scripts/close-issue.sh <issue_number> [--dry-run]" >&2
  exit 1
fi

# ── Load env vars from ~/.aic-env (manual fallback if aic did not inject) ──
AIC_ENV_FILE="${HOME}/.aic-env"
if [[ -f "$AIC_ENV_FILE" ]]; then
  # Only import GITLAB_TOKEN / GITHUB_TOKEN; do not pollute other variables
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^(GITLAB_TOKEN|GITHUB_TOKEN)$ ]] || continue
    [[ -z "${!key:-}" ]] && export "$key"="$value"
  done < <(grep -E '^(GITLAB_TOKEN|GITHUB_TOKEN)=' "$AIC_ENV_FILE" 2>/dev/null || true)
fi

# ── Parse remote URL ──────────────────────────────────────────
REMOTE_URL="$(git remote get-url origin 2>/dev/null || echo "")"
if [[ -z "$REMOTE_URL" ]]; then
  echo "Error: cannot get git remote origin URL" >&2
  exit 1
fi

# Supports SSH (git@host:ns/repo.git) and HTTPS (https://host/ns/repo.git)
if [[ "$REMOTE_URL" =~ ^git@([^:]+):(.+)/([^/]+)\.git$ ]]; then
  HOST="${BASH_REMATCH[1]}"
  NAMESPACE="${BASH_REMATCH[2]}"
  REPO="${BASH_REMATCH[3]}"
elif [[ "$REMOTE_URL" =~ ^https?://([^/]+)/(.+)/([^/]+)(\.git)?$ ]]; then
  HOST="${BASH_REMATCH[1]}"
  NAMESPACE="${BASH_REMATCH[2]}"
  REPO="${BASH_REMATCH[3]}"
else
  echo "Error: cannot parse remote URL: $REMOTE_URL" >&2
  exit 1
fi

# ── Detect platform ───────────────────────────────────────────
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

# ── Dry-run preview (no token needed) ─────────────────────────
if $DRY_RUN; then
  echo "[dry-run] Platform: $PLATFORM"
  echo "[dry-run] Project: ${NAMESPACE}/${REPO}"
  echo "[dry-run] API: ${HTTP_METHOD} $API_URL"
  echo "[dry-run] Will close Issue #${ISSUE_NUMBER}"
  exit 0
fi

# ── Token validation (only needed for actual API calls) ───────
if [[ "$PLATFORM" == "github" ]]; then
  TOKEN="${GITHUB_TOKEN:-}"
  if [[ -z "$TOKEN" ]]; then
    echo "⚠️  Skipping issue close: GITHUB_TOKEN not found (configure via aic env add, or install glab-manage skill)" >&2
    exit 0
  fi
  AUTH_HEADER="Authorization: Bearer ${TOKEN}"
else
  TOKEN="${GITLAB_TOKEN:-}"
  if [[ -z "$TOKEN" ]]; then
    echo "⚠️  Skipping issue close: GITLAB_TOKEN not found (configure via aic env add, or install glab-manage skill)" >&2
    exit 0
  fi
  AUTH_HEADER="PRIVATE-TOKEN: ${TOKEN}"
fi

# ── Call API ──────────────────────────────────────────────────
HTTP_CODE="$(curl -s -o /tmp/close_issue_resp.json -w "%{http_code}" \
  -X "$HTTP_METHOD" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d "$PAYLOAD" \
  "$API_URL")"

if [[ "$HTTP_CODE" =~ ^2 ]]; then
  echo "Issue #${ISSUE_NUMBER} closed ($PLATFORM)"
else
  echo "Error: API returned HTTP $HTTP_CODE" >&2
  cat /tmp/close_issue_resp.json >&2
  exit 1
fi

# ── Update dev-plan.md ────────────────────────────────────────
DEV_PLAN_PATH="docs/dev-plan.md"
if [[ ! -f "$DEV_PLAN_PATH" ]]; then
  exit 0
fi

# Mark the status of the matching Issue line in dev-plan.md as completed
# Matches: | in progress | or **Status**: in progress → replaced with completed
python3 - "$DEV_PLAN_PATH" "$ISSUE_NUMBER" <<'PYEOF'
import sys
import re

plan_path = sys.argv[1]
issue_num = sys.argv[2]

with open(plan_path, encoding="utf-8") as f:
    content = f.read()

issue_pattern = re.compile(r"Issue[^#\n]*#" + re.escape(issue_num) + r"\b")
heading_pattern = re.compile(r"^#{1,6}\s", re.MULTILINE)

# Split into blocks; if no headings, treat the whole file as one block
headings = [m.start() for m in heading_pattern.finditer(content)]
if not headings:
    headings = [0]
headings.append(len(content))

def replace_status(block):
    # Match **Status:** / **Status**: / Status: in various formats
    b = re.sub(r"(\*{0,2}Status\*{0,2}[:：]\*{0,2}\s*)(in progress)", r"\1completed", block, flags=re.IGNORECASE)
    # Table row format: | in progress |
    b = re.sub(r"(\|\s*)(in progress)(\s*\|)", r"\1completed\3", b, flags=re.IGNORECASE)
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
    print(f"dev-plan.md updated: Issue #{issue_num} status → completed")
else:
    print(f"dev-plan.md: no updatable status line found for Issue #{issue_num} (may already be up to date)")
PYEOF
