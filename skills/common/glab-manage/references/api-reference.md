# GitLab API 调用参考

> 优先使用 Web API（仅需 curl + GITLAB_TOKEN），无需额外安装工具。
> 执行前先读取当前项目 `.aic/.aic-env`，若缺失再读取 `~/.aic/aic-env`。规则：project 优先于 global；缺失变量时必须停止并提示用户补齐。

---

## 环境变量说明

```bash
GITLAB_URL=<GITLAB_URL>                    # GitLab 实例地址
GITLAB_TOKEN={{GITLAB_TOKEN}}                # Personal Access Token（api scope）
GITLAB_PROJECT_ID=<from .aic/.aic-env or ~/.aic/aic-env>      # 项目数字 ID（推荐）
```

**获取项目 ID：**
```bash
/usr/bin/curl -s -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  "<GITLAB_URL>/api/v4/projects?search=my-project" | python3 -m json.tool | grep '"id"'
```

---

## 标准调用模板（必须使用此模板，防止 JSON 污染）

所有 API 调用必须遵循以下模式：

```bash
# 1. 用 -o 将响应体写入临时文件，-w 单独捕获 HTTP 状态码
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" \
  -w "%{http_code}" \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  "<GITLAB_URL>/api/v4/...")

# 2. 检查 HTTP 状态码
if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "201" ]]; then
  echo "API 错误 HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2
  rm -f "$RESP_FILE"
  exit 1
fi

# 3. 验证响应是合法 JSON，再传给 jq
if ! /usr/bin/jq empty "$RESP_FILE" 2>/dev/null; then
  echo "响应非 JSON，原始内容：$(cat "$RESP_FILE")" >&2
  rm -f "$RESP_FILE"
  exit 1
fi

# 4. 解析所需字段
RESULT=$(/usr/bin/jq -r '.id' "$RESP_FILE")
rm -f "$RESP_FILE"
```

**关键规则：**
- `curl` 和 `jq` 必须使用绝对路径 `/usr/bin/curl`、`/usr/bin/jq`
- 响应体和状态码必须分离（`-o file -w "%{http_code}"`），禁止 `curl ... | jq`
- jq 解析前必须先 `jq empty` 验证 JSON 合法性

---

## Milestone API

### 查询已有 Milestone（选择关联用）

```bash
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/milestones?state=active&order_by=created_at&sort=desc")
[[ "$HTTP_CODE" != "200" ]] && { echo "HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq empty "$RESP_FILE" 2>/dev/null || { echo "非 JSON 响应: $(cat "$RESP_FILE")" >&2; exit 1; }

# 展示所有 milestone 供选择
/usr/bin/jq -r '.[] | "\(.id)\t\(.title)"' "$RESP_FILE"

# 取最新一个（默认选择）
MILESTONE_ID=$(/usr/bin/jq -r '.[0].id' "$RESP_FILE")
MILESTONE_TITLE=$(/usr/bin/jq -r '.[0].title' "$RESP_FILE")
rm -f "$RESP_FILE"
echo "默认关联 Milestone: [$MILESTONE_ID] $MILESTONE_TITLE"
```

返回空数组时说明项目无 Milestone，必须停止并提示用户先创建。

---

## Issue API

### 查询已有 Issue（用于去重）

```bash
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/issues?state=opened&per_page=100")
[[ "$HTTP_CODE" != "200" ]] && { echo "HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq empty "$RESP_FILE" 2>/dev/null || { echo "非 JSON 响应: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq -r '.[].title' "$RESP_FILE"
rm -f "$RESP_FILE"
```

### 创建 Issue（含三类标签）

```bash
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -X POST \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "[Task Phase 2.5] 实现 SKILL.md frontmatter 解析",
    "description": "## 任务目标\n...\n\n## 验收标准\n- [ ] go test 通过",
    "milestone_id": 12,
    "labels": "P1,type::task,task::todo",
    "assignee_ids": [123],
    "weight": 2
  }' \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/issues")
[[ "$HTTP_CODE" != "201" ]] && { echo "HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq empty "$RESP_FILE" 2>/dev/null || { echo "非 JSON 响应: $(cat "$RESP_FILE")" >&2; exit 1; }
ISSUE_IID=$(/usr/bin/jq -r '.iid' "$RESP_FILE")
rm -f "$RESP_FILE"
echo "Issue #$ISSUE_IID"
```

返回值中的 `iid` 字段即为项目内 Issue 编号（如 #42）。

**assignee_ids 说明：**
- 值为用户数字 ID 的单元素数组，如 `[123]`
- `GITLAB_ASSIGNEE_ID` 不为空时直接使用该值；为空时先查询成员列表让用户选择
- 不指派时传空数组 `[]` 或省略该字段

### 查询项目成员（GITLAB_ASSIGNEE_ID 为空时使用）

```bash
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/members?per_page=50")
[[ "$HTTP_CODE" != "200" ]] && { echo "HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq empty "$RESP_FILE" 2>/dev/null || { echo "非 JSON 响应: $(cat "$RESP_FILE")" >&2; exit 1; }
# 展示成员列表：ID + 用户名
/usr/bin/jq -r '.[] | "\(.id)\t\(.username)\t\(.name)"' "$RESP_FILE"
rm -f "$RESP_FILE"
```
- task 类型：`"P1,type::task,task::todo"`
- bug 类型：`"P0,type::bug,bug::open"`
- prd 类型：`"P2,type::prd,prd::todo"`

---

## Issue 关闭流程 API

关闭 Issue 前必须先更新状态标签，分两步执行：

### Step 1：更新状态标签（移除旧状态，添加终态）

```bash
# 先查询 Issue 当前标签
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/issues/{issue_iid}")
[[ "$HTTP_CODE" != "200" ]] && { echo "HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
CURRENT_LABELS=$(/usr/bin/jq -r '.labels | join(",")' "$RESP_FILE")
rm -f "$RESP_FILE"

# 构造新标签列表：移除旧状态标签，添加终态标签
# type::task → 移除 task::todo/task::doing，添加 task::done
# type::bug  → 移除 bug::open/bug::fixing，添加 bug::close
# type::prd  → 移除 prd::todo/prd::doing，添加 prd::done
NEW_LABELS="P1,type::task,task::done"   # 根据实际情况构造

RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -X PUT \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  -H "Content-Type: application/json" \
  -d "{\"labels\": \"$NEW_LABELS\"}" \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/issues/{issue_iid}")
[[ "$HTTP_CODE" != "200" ]] && { echo "标签更新失败 HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
rm -f "$RESP_FILE"
echo "标签已更新为终态"
```

### Step 2：关闭 Issue

```bash
RESP_FILE=$(mktemp)
HTTP_CODE=$(/usr/bin/curl -s \
  -o "$RESP_FILE" -w "%{http_code}" \
  -X PUT \
  -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
  -H "Content-Type: application/json" \
  -d '{"state_event": "close"}' \
  "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/issues/{issue_iid}")
[[ "$HTTP_CODE" != "200" ]] && { echo "关闭失败 HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2; exit 1; }
/usr/bin/jq empty "$RESP_FILE" 2>/dev/null || { echo "非 JSON 响应: $(cat "$RESP_FILE")" >&2; exit 1; }
rm -f "$RESP_FILE"
echo "Issue #{issue_iid} 已关闭"
```

---

## Label API（确保标签存在）

首次使用时，确保项目已创建以下标签（已存在时 409 忽略）：

```bash
LABELS=(
  "P0:#FF0000" "P1:#FF6600" "P2:#FFAA00" "P3:#AAAAAA"
  "type::task:#428BCA" "type::bug:#D9534F" "type::prd:#5CB85C"
  "task::todo:#CCCCCC" "task::doing:#5BC0DE" "task::done:#5CB85C"
  "bug::open:#D9534F" "bug::fixing:#F0AD4E" "bug::close:#AAAAAA"
  "prd::todo:#CCCCCC" "prd::doing:#5BC0DE" "prd::done:#5CB85C"
)

for entry in "${LABELS[@]}"; do
  label="${entry%%:*}"
  color="${entry##*:}"
  RESP_FILE=$(mktemp)
  HTTP_CODE=$(/usr/bin/curl -s \
    -o "$RESP_FILE" -w "%{http_code}" \
    -X POST \
    -H "PRIVATE-TOKEN: {{GITLAB_TOKEN}}" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$label\", \"color\": \"$color\"}" \
    "<GITLAB_URL>/api/v4/projects/<GITLAB_PROJECT_ID>/labels")
  # 409 = 已存在，正常忽略
  [[ "$HTTP_CODE" != "201" && "$HTTP_CODE" != "409" ]] \
    && echo "Label '$label' 创建失败 HTTP $HTTP_CODE: $(cat "$RESP_FILE")" >&2
  rm -f "$RESP_FILE"
done
```

---

## 错误处理

| HTTP 状态码 | 含义 | 处理方式 |
|-------------|------|----------|
| 401 | Token 无效或过期 | 提示用户重新生成 Token |
| 403 | 权限不足 | 检查 Token scope 是否包含 api |
| 404 | 项目不存在 | 确认 GITLAB_PROJECT_ID 是否正确 |
| 409 | 资源冲突（如 Label 已存在）| 忽略，继续 |
| 429 | 请求频率超限 | 每次请求间隔 0.2s，批量创建时添加延迟 |
| 非 JSON 响应 | GitLab 返回 HTML 错误页（502/认证失败）| 打印原始内容，终止脚本 |
