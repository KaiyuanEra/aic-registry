# GitLab API Call Reference

> Prefer the Web API (only needs curl + GITLAB_TOKEN); no extra tools to install.
> Before execution, read the current project .aic/.aic-env; if missing, read ~/.aic/aic-env. Rule: project takes priority over global; when variables are missing, stop and prompt the user to fill them in.

---

## Environment Variables

```bash
GITLAB_URL=<GITLAB_URL>                    # GitLab instance URL
GITLAB_TOKEN={{GITLAB_TOKEN}}                # Personal Access Token (api scope)
GITLAB_PROJECT_ID=<from .aic/.aic-env or ~/.aic/aic-env>      # Project numeric ID (recommended)
```

**Get project ID:**
```bash
/usr/bin/curl -s -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  "<GITLAB_URL>/api/v4/projects?search=my-project" | python3 -m json.tool | grep id
```

---

## Standard Call Template (must use this template to prevent JSON pollution)

All API calls must follow this pattern:

```bash
# 1. Write response body to a temp file with -o; capture HTTP status code separately with -w
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" \
  -w "%{http_code}" \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  "<GITLAB_URL>/api/v4/...")

# 2. Check HTTP status code
if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "201" ]]; then
  echo "API error HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2
  rm -f "$RESP_FILE"
  exit 1
fi

# 3. Validate response is valid JSON before passing to jq
if ! /usr/bin/jq empty "$RESP_FILE" 2>/dev/null; then
  echo "Response is not JSON, raw content: $(cat "$RESP_FILE")" >&2
  rm -f "$RESP_FILE"
  exit 1
fi

# 4. Parse the required fields
RESULT=$(/usr/bin/jq -r '.id' "$RESP_FILE")
rm -f "$RESP_FILE"
```

**Key rules:**
- curl and jq must use absolute paths /usr/bin/curl, /usr/bin/jq
- Response body and status code must be separated (-o file -w "%{http_code}"); never use curl ... | jq
- Validate JSON with jq empty before parsing

---

## Milestone API

### Query existing milestones (for linking)

```bash
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/milestones?state=active&order_by=created_at&sort=desc")
[[ "$HTTP_CODE" != "200" ]] && { echo "HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq empty "$RESP_FILE" 2>/dev/null || { echo "Non-JSON response: $(cat "$RESP_FILE")" >&2; exit 1; }

# Show all milestones for selection
/usr/bin/jq -r '.[] | "\(.id)\t\(.title)"' "$RESP_FILE"

# Take the most recent one (default selection)
MILESTONE_ID=$(/usr/bin/jq -r '.[0].id' "$RESP_FILE")
MILESTONE_TITLE=$(/usr/bin/jq -r '.[0].title' "$RESP_FILE")
rm -f "$RESP_FILE"
echo "Default linked milestone: [$MILESTONE_ID] $MILESTONE_TITLE"
```

An empty array means no milestones; stop and prompt the user to create one first.

---

## Issue API

### Query existing issues (for deduplication)

```bash
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/issues?state=opened&per_page=100")
[[ "$HTTP_CODE" != "200" ]] && { echo "HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq empty "$RESP_FILE" 2>/dev/null || { echo "Non-JSON response: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq -r '.[].title' "$RESP_FILE"
rm -f "$RESP_FILE"
```

### Create issue (with three label categories)

```bash
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -X POST \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "[Task Phase 2.5] Implement SKILL.md frontmatter parsing",
    "description": "## Task Objective\n...\n\n## Acceptance Criteria\n- [ ] go test passes",
    "milestone_id": 12,
    "labels": "P1,type::task,task::todo",
    "assignee_ids": [123],
    "weight": 2
  }' \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/issues")
[[ "$HTTP_CODE" != "201" ]] && { echo "HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq empty "$RESP_FILE" 2>/dev/null || { echo "Non-JSON response: $(cat "$RESP_FILE")" >&2; exit 1; }
ISSUE_IID=$(/usr/bin/jq -r '.iid' "$RESP_FILE")
rm -f "$RESP_FILE"
echo "Issue #$ISSUE_IID"
```

The `iid` field in the response is the project-scoped issue number (e.g. #42).

**assignee_ids notes:**
- Value is a single-element array of user numeric IDs, e.g. [123]
- When GITLAB_ASSIGNEE_ID is non-empty, use it directly; when empty, query the member list first for the user to choose
- When not assigning, pass an empty array [] or omit the field

### Query project members (when GITLAB_ASSIGNEE_ID is empty)

```bash
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/members?per_page=50")
[[ "$HTTP_CODE" != "200" ]] && { echo "HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq empty "$RESP_FILE" 2>/dev/null || { echo "Non-JSON response: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq -r '.[] | "ID: \(.id)  Username: \(.username)  Name: \(.name)"' "$RESP_FILE"
rm -f "$RESP_FILE"
```

### Update issue labels (for close flow)

```bash
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -X PUT \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  -H "Content-Type: application/json" \
  -d '{"labels": "P1,type::task,task::done"}' \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/issues/<ISSUE_IID>")
[[ "$HTTP_CODE" != "200" ]] && { echo "HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq empty "$RESP_FILE" 2>/dev/null || { echo "Non-JSON response: $(cat "$RESP_FILE")" >&2; exit 1; }
rm -f "$RESP_FILE"
echo "Labels updated"
```

### Close issue

```bash
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -X PUT \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  -H "Content-Type: application/json" \
  -d '{"state_event": "close"}' \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/issues/<ISSUE_IID>")
[[ "$HTTP_CODE" != "200" ]] && { echo "HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq empty "$RESP_FILE" 2>/dev/null || { echo "Non-JSON response: $(cat "$RESP_FILE")" >&2; exit 1; }
rm -f "$RESP_FILE"
echo "Issue #<ISSUE_IID> closed"
```

---

## Common Errors

| Error | Cause | Handling |
|------|------|----------|
| HTTP 401 | Token expired or insufficient permissions | Re-check GITLAB_TOKEN; ensure api scope |
| HTTP 404 | Wrong project ID or path | Use GET /api/v4/projects?search=xxx to confirm |
| HTTP 429 | Rate limited | Add 2s delay for batch creation |
| Non-JSON response | GitLab returns HTML error page (502/auth failure) | Print raw content; terminate script |
