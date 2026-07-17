---
name: glab-manage
version: 3.0.1
description: >
  根据开发计划在 GitLab 上创建 Issue，关联现有 Milestone，并将编号回写到 dev-plan.md。
  Use when creating GitLab issues, syncing a dev plan to GitLab,
  or when user mentions 建 issue、同步计划到 GitLab、
  glab、GitLab issue、issue 编号回写、同步任务、这期迭代建一下、关闭 issue、close issue。
  Do NOT use for 本地 git commit（使用 git-commit skill）、
  只查看 GitLab 信息而不创建，或拉取 / 推送代码操作，或创建 Milestone。
tags: [gitlab, project-management, dev-workflow]
env-required: true
env-vars:
  - name: GITLAB_URL
    description: GitLab 实例地址，如 https://git.ifogging.cn
    required: true
    default: "https://git.ifogging.cn"
    target: skill
  - name: GITLAB_TOKEN
    description: Personal Access Token，需要 api scope（创建 Issue 权限）
    required: true
    target: skill
  - name: GITLAB_PROJECT_ID
    description: 项目数字 ID（首选）或路径，如 rd/backend/my-project
    required: true
  - name: GITLAB_ASSIGNEE_ID
    description: >-
      默认指派人的 GitLab 用户数字 ID。查询方式：curl -s -H "PRIVATE-TOKEN:<token>"
      "<GITLAB_URL>/api/v4/user" | python3 -m json.tool | grep id，
      或 GitLab 页面：头像 → Edit profile → 页面顶部 User ID
    required: true
    target: skill
---

# glab-manage

根据 `docs/dev-plan.md` 中的 Phase/Task 结构，在 GitLab 创建 Issue，关联现有 Milestone，并将 Issue 编号回写到计划文档。

**对应关系：** Task → Issue（Milestone 只关联，不自动创建）

---

## Milestone 选择策略

**不自动创建 Milestone**，执行前先查询项目现有 Milestone：

```
① 查询项目所有 active Milestone
② 若只有一个 → 直接使用，告知用户
③ 若有多个   → 默认选最新创建的一个，展示给用户确认
              → 用户可指定其他 Milestone
④ 若一个都没有 → 停止，提示用户先在 GitLab 创建 Milestone 后再执行
```

> ⚠️ 项目暂无 Milestone，无法创建 Issue。
> 请先在 GitLab 项目页面「计划 → 里程碑」中创建 Milestone，完成后重新执行。

**存在歧义时必须询问用户**，不得自行猜测选择。

---

## 新项目 vs 老项目判断

```
新项目信号（全量创建）：
  ① dev-plan.md 中 Task 的 Issue 字段全部为"#（待创建）"
  ③ 用户明确说"新项目"/"从头开始"

老项目信号（增量维护）：
  ① dev-plan.md 中部分 Task 已有 Issue 编号
  ② 用户明确说"补充"/"新增需求"/"这期迭代"

无法判断时：展示两种模式差异，询问用户选择
```

详细判断逻辑见 [references/new-vs-legacy.md](references/new-vs-legacy.md)。

---

## API 调用策略

优先级：**GitLab Web API（curl）> glab CLI > 提示用户配置**

```bash
# 执行前自动检测：
# 1. GITLAB_TOKEN 存在 → 使用 Web API
# 2. glab 在 PATH  → 使用 glab CLI
# 3. 均无           → 提示配置步骤
```

**脚本生成规范（AI 必须严格遵守）：**

| 规则 | 原因 |
|------|------|
| `curl` 使用绝对路径 `/usr/bin/curl` | Claude Code 执行 bash 时 PATH 是精简环境，`curl` 可能找不到 |
| `jq` 使用绝对路径 `/usr/bin/jq` | 同上 |
| 响应体和状态码分离：`-o file -w "%{http_code}"` | 禁止 `curl ... \| jq`，避免 stderr/进度信息污染管道 |
| jq 解析前先 `jq empty` 验证 | GitLab 在 401/502 时返回 HTML，直接传给 jq 会 parse error |
| 非 200/201 状态码立即打印原始响应并退出 | 快速定位是 Token 失效、项目 ID 错误还是网络问题 |

完整防御性调用模板见 [references/api-reference.md](references/api-reference.md)。

---

## Issue 权重规范

**计量单位：** 半天（4 小时）= 1 个权重

| 预估工时 | 权重值 |
|----------|--------|
| ≤ 4h | 1 |
| 5–8h | 2 |
| 9–12h | 3 |
| 13–16h | 4 |
| 每增加 4h | +1 |

**工时来源（按优先级）：**

1. 从 dev-plan.md 对应 Task 的 `**预估：** {n} 小时` 字段提取，换算公式：`weight = ceil(小时数 / 4)`
2. 提取不到时，根据任务标题和描述评估一个合理值，**展示给用户确认后再使用**，不得静默写入

---

## Issue 创建粒度

创建前先确认粒度（若用户未指定则询问）：

| 粒度 | 说明 | 适用场景 |
|------|------|----------|
| **Phase 粒度**（推荐） | 每个 Phase 创建一个 Issue，Tasks 作为描述内的 checklist | 对外汇报进度、milestone 跟踪 |
| **Task 粒度** | 每个 Task 创建一个 Issue | 精细分工、多人协作 |

两种粒度可混用：同一次操作中，部分 Phase 用 Phase 粒度，部分用 Task 粒度。

---

### Phase 粒度 Issue 规范

**标题格式：**
```
[Task] {Phase 功能名}
示例：[Task] 用户登录与权限校验
```

**描述格式（自动从 dev-plan.md 生成）：**
```markdown
## Phase 目标
{Phase 标题行中的功能名，即对下方 Task 实现目标的简要总结}

## 任务清单
- [ ] Task 1.1: {Task 名称}（预估 {n}h）
- [ ] Task 1.2: {Task 名称}（预估 {n}h）
- [ ] Task 1.3: {Task 名称}（预估 {n}h）

## 验收标准
{汇总各 Task 的输出产物，一句话描述 Phase 整体交付物}
```

**权重：** Phase 下所有 Task `**预估：**` 字段小时数累加后换算，`weight = ceil(总小时数 / 4)`

**标签：** 三类标签规则与 Task 粒度相同，类型默认 `type::task`

---

## Issue 创建粒度

标题前缀根据 **类型** 和 **来源** 确定：

| 类型 | 来自 dev-plan（有 Phase 信息） | 无 Phase 信息 |
|------|-------------------------------|---------------|
| task | `[Task Phase 2.5] 描述` | `[Task] 描述` |
| bug  | `[Bug] 描述` | `[Bug] 描述` |
| prd  | `[PRD] 描述` | `[PRD] 描述` |

- Phase 编号从 dev-plan.md 的 Phase 结构中提取（如 Phase 2.5 → `Phase 2.5`）
- Bug 和 PRD 类型固定使用简短前缀，不附加 Phase 编号

---

## Issue 标签规范（三类必填）

每个 Issue 创建时必须打上以下三类标签，缺一不可：

### 1. 优先级标签（选一）

| 标签 | 含义 |
|------|------|
| `P0` | 紧急 |
| `P1` | 高 |
| `P2` | 中 |
| `P3` | 低 |

### 2. 类型标签（选一）

| 标签 | 含义 |
|------|------|
| `type::task` | 任务（拆分任务） |
| `type::bug` | 缺陷 |
| `type::prd` | 需求 |

### 3. 状态标签（根据类型选一）

**type::task：**

| 标签 | 含义 |
|------|------|
| `task::todo` | 待处理 |
| `task::doing` | 处理中 |
| `task::done` | 已完成 |

**type::bug：**

| 标签 | 含义 |
|------|------|
| `bug::open` | 待修复 |
| `bug::fixing` | 修复中 |
| `bug::close` | 已关闭 |

**type::prd：**

| 标签 | 含义 |
|------|------|
| `prd::todo` | 待处理 |
| `prd::doing` | 设计中 |
| `prd::done` | 已完成 |

**创建 Issue 时的默认初始状态：**
- task → `task::todo`
- bug → `bug::open`
- prd → `prd::todo`

**标签收集交互：** 若用户未指定优先级，展示 P0~P3 选项让用户确认，不得自行假设。

---

## Issue 关闭流程

执行 close 操作时，**必须先更新状态标签，再关闭 Issue**：

```
① 查询 Issue 当前标签，识别状态标签
② 移除旧状态标签
③ 添加终态标签：
     type::task → task::done
     type::bug  → bug::close
     type::prd  → prd::done
④ 调用 close API 关闭 Issue
```

API 调用顺序见 [references/api-reference.md](references/api-reference.md)。

---

## 工作流程

### 全量创建（新项目）

1. **查询 Milestone** — 按选择策略确定关联的 Milestone ID
2. **读取** `docs/dev-plan.md`，提取所有 Phase 和 Task
3. **确认粒度** — Phase 粒度 or Task 粒度（见上方说明）
4. **收集标签信息** — 确认优先级（批量时可统一设置默认值）
5. **创建 Issue** — 按选定粒度创建，关联 Milestone，打三类标签
6. **回写编号** — 将 Issue 编号回写到 dev-plan.md 对应位置
7. **自动 commit** — `docs: 同步 GitLab Issue 编号到开发计划`

### 增量维护（老项目）

1. **查询 Milestone** — 同上
2. **读取** dev-plan.md，筛选 Issue 字段仍为 `#（待创建）` 的 Phase 或 Task
3. **确认粒度** — 同上
4. **仅创建** 缺失的 Issue
5. **跳过** 已有 Issue 编号的条目和已关闭的 Issue
6. **回写 + commit**（同上）

---

## Issue 描述模板

```markdown
## 任务目标
{从 dev-plan.md Task 描述提取}

## 涉及文件
{从 dev-plan.md 提取，无则留空}

## 验收标准
- [ ] {验收项}

## 备注
{其他说明}
```

---

## 回写机制

**Task 粒度回写（原有行为）：**
```
从：- **Issue：** #（待创建）
到：- **Issue：** #42
```

**Phase 粒度回写（新增）：**

回写到 Phase 标题行，格式：
```
### Phase 1: 用户登录与权限校验 | 预估工期：4天 | 优先级：P1 | Issue: #12 | 状态：🔄 进行中
```

Issue 关闭后，同步更新状态字段：
```
### Phase 1: 用户登录与权限校验 | 预估工期：4天 | 优先级：P1 | Issue: #12 | 状态：✅ 已完成（{YYYY-MM-DD}）
```

**执行方式：** 调用 `scripts/writeback.sh`，失败时输出待手动填写的映射表，不中断流程。

---

## 常见边缘情况

| 情况 | 处理方式 |
|------|----------|
| 无 dev-plan.md | 降级：直接与用户对话收集信息，逐条手动创建；提示先用 dev-plan skill |
| 无 Milestone | 停止，提示用户先在 GitLab 创建 Milestone |
| GITLAB_TOKEN 权限不足 | 明确说明需要 api scope，给出 Token 创建链接 |
| 项目 ID 错误 | 先调用 `GET /api/v4/projects?search=xxx` 帮用户确认正确 ID |
| 网络超时 | 已创建的部分记录进度，提示用户重试时跳过已创建项 |
| Issue 标题重复 | 先查询再创建，标题完全匹配则跳过，输出已跳过清单 |
| close 时无状态标签 | 警告用户，询问是否直接关闭或先手动补打标签 |
