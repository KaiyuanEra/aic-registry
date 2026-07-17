---
name: dev-plan
version: 2.0.3
description: >
  生成或增量更新项目开发计划文档 dev-plan.md，拆分 Phase/Task 结构，支持 Phase 级归档与文档长度管理。
  Use when writing a development plan, breaking down a PRD into tasks, updating an existing plan, archiving completed phases,
  or when user mentions 制定开发计划、拆分任务、更新计划、项目规划、需求拆分、
  技术方案、任务列表、Phase 划分、dev-plan、PRD、里程碑规划、归档 Phase、精简计划。
  Do NOT use for 创建 GitLab Issue 或 Milestone（使用 glab-manage skill），
  git commit 操作（使用 git-commit skill），或纯粹的技术实现问题。
tags: [planning, dev-workflow, docs]
env-required: false
---

# dev-plan

根据需求输入生成或增量更新 `dev-plan.md`，为 AI 工具提供稳定的开发上下文锚点。同时支持 Phase 级归档，保持活跃文档长度有界。

**核心价值：** 任务级拆分（2–8 小时 + 具体文件路径）= 低参模型也能准确执行。

**v2.0 新增：** Phase 级归档机制 + 文档大小监控 + 前置校验 + 回退查找。

---

## 文件位置约定

```
项目根目录/
├── dev-plan.md                    ← 活跃文档（当前 + 未来 Phase + 归档索引表）
└── docs/
    └── dev-plan-archive/
        ├── phase-1.md             ← 已完成 Phase 的完整归档文件
        ├── phase-2.md
        └── ...
```

**初始化规则：**
- 新建 dev-plan.md 时，文件位置为**项目根目录**
- 首次执行归档时，自动创建 `docs/dev-plan-archive/` 目录（若不存在）

**dev-plan.md 的结构：**
```markdown
# {项目名} 开发计划

> 最后更新：{date} | 版本：v{n}
> 已归档：Phase 1 → docs/dev-plan-archive/phase-1.md

## 已归档 Phase 索引

| Phase | 阶段名 | 完成时间 | Task 数 | Issue 范围 |
|-------|--------|---------|--------|-----------|
| Phase 1 | 基础数据层 | 2026-05-12 | 6 | #1-#6 |
| Phase 2 | Git 仓库 | 2026-05-20 | 5 | #7-#11 |

---

## 变更记录
...

## 1. 项目概述
...
```

**索引表的作用：**
- 集中记录所有已归档 Phase 的元数据
- 提供 Issue 编号范围，便于 glab-manage / git-commit 快速查找
- 其他 skill 无需修改，直接从 dev-plan.md 中查询

---

## 工作模式

### 模式 1：新建

```
检测 dev-plan.md 是否存在：

不存在 → 新建模式
  收集输入 → 生成完整文档 → 写入 {project_root}/dev-plan.md
```

### 模式 2：增量更新

```
存在 → 增量模式
  读取现有文档 → 识别变更范围 → 只修改受影响章节
  在文件头部 changelog 追加本次变更记录
  已完成 Task（✅ 或有 Issue 编号）不重写，只允许追加 Note
```

### 模式 3：Phase 归档（v2.0 新增）

```
用户发起归档请求 → 执行前置校验 → 通过后执行归档流程
  Step 1：创建 docs/dev-plan-archive/ 目录
  Step 2：生成 phase-{N}.md 归档文件
  Step 3：从 dev-plan.md 删除目标 Phase 块
  Step 4：更新 dev-plan.md 顶部已归档声明
  Step 5：在变更记录中追加归档记录
  Step 6：输出归档报告

详见 references/archive-guide.md
```

---

## 工作流程

1. **收集输入** — 用户提供：需求文档 / PRD / 功能描述 / 已有代码库
2. **判断模式** — 检测 `dev-plan.md` 是否存在，选择新建 / 增量 / 归档模式
3. **生成内容** — 按文档结构规范输出（见下方）
4. **写入文件** — 调用 Write tool：
   - `file_path`：`{project_root}/dev-plan.md`（用 Bash `pwd` 获取绝对路径）
   - `content`：生成的完整文档文本
5. **文档大小检查** — 生成后检查行数：
   - **< 300 行**：正常，输出完成提示
   - **300–400 行**：黄色警告，提示可考虑归档已完成 Phase
   - **> 400 行**：红色警告，强烈建议执行 Phase 归档
6. **提示后续** — 输出完成后提示：可用 `glab-manage` skill 同步到 GitLab，或用本 skill 执行 Phase 归档

---

## 文档结构

文件位置：`{project_root}/dev-plan.md`

```markdown
# {项目名} 开发计划

> 最后更新：{YYYY-MM-DD} | 版本：v{n} | 状态：进行中
> 已归档：Phase 1 → docs/dev-plan-archive/phase-1.md（无归档时此行省略）

## 已归档 Phase 索引

| Phase | 阶段名 | 完成时间 | Task 数 | Issue 范围 |
|-------|--------|---------|--------|-----------|
| （无） | - | - | - | -（无归档时保留此占位行）|

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v{n} | {date} | {变更说明} |

---

## 1. 项目概述
### 1.1 背景与目标
### 1.2 核心用户场景（3-5 条）
### 1.3 范围边界（做什么 / 不做什么）

## 2. 技术栈
| 层次 | 技术选型 | 版本 | 选型理由 |

## 3. 整体架构设计
### 3.1 架构图（ASCII 或 Mermaid）
### 3.2 模块职责说明
### 3.3 关键数据流

## 4. 项目结构
（目录树 + 关键文件一句话说明）

## 5. 开发计划
### Phase 1: {功能名} | 预估工期：{n}天 | 优先级：P0 | Issue: #（待创建） | 状态：🔄 进行中
#### Task 1.1: {动词短语}
- 目标 / 涉及文件 / 输入 / 输出 / 预估 / Issue / 注意
```

**永久保留章节：** 第 1–4 章（概述/技术栈/架构/结构）始终保留在活跃文档中，不参与归档。

详细模板见 [assets/dev-plan.template.md](assets/dev-plan.template.md)。

---

## Phase 命名规范（强制）

Phase 名称必须是**人类可读的功能/问题描述**，而非技术模块名。命名原则：

- **实现功能**：描述交付了什么能力，用户/业务视角
- **解决问题**：描述修复了什么问题或消除了什么风险
- **修复 Bug**：描述 Bug 的现象或影响范围

| ❌ 不合规（技术模块名） | ✅ 合规（功能/问题描述） |
|------------------------|------------------------|
| `Phase 1: 核心基础模块` | `Phase 1: 用户登录与权限校验` |
| `Phase 2: CLI 交互层` | `Phase 2: 命令行安装与配置向导` |
| `Phase 3: Parser 重构` | `Phase 3: 修复多窗口并存时的少算问题` |
| `Phase 4: 性能优化` | `Phase 4: 降低高并发下的 P99 延迟至 50ms 以内` |

**校验规则：** Phase 名称中不得出现纯技术词汇（如 `模块`、`层`、`重构`、`优化`）作为主语，必须能回答"这个 Phase 完成后，用户/业务得到了什么？"

---

## Task 拆分核心标准

**粒度：** 2–8 小时内可完成 + 对应 1–3 个具体文件改动

每个 Task 必须满足：

| 检查项 | 示例 |
|--------|------|
| 任务名是动词短语 | ✅ "实现 SKILL.md frontmatter 解析" ❌ "Parser 模块" |
| 涉及文件明确到路径 | `internal/skill/parser.go` |
| 输入依赖明确 | "依赖 Task 1.2 完成" 或 "无依赖" |
| 输出产物明确 | 函数签名 / 接口 / API 端点 |
| 预估 2–8 小时 | 超出则继续拆分 |
| 验收标准可被 AI 自验 | 能运行 / 测试通过 / 输出符合格式 |

详细拆分方法见 [references/task-split-guide.md](references/task-split-guide.md)。

---

## 增量更新约束

- 变更记录只追加，不修改历史（超过 5 条时截断最早的）
- 已有 Issue 编号的 Task 不重写，只能追加 Note
- 新增 Phase/Task 在末尾追加，编号连续
- 修改现有 Task 内容时：原内容加删除线，再写新内容

详细规范见 [references/incremental-update.md](references/incremental-update.md)。

---

## Phase 归档流程（v2.0 新增）

### 触发条件

用户明确发起归档请求：
- "归档 Phase N"
- "Phase N 已完成，精简开发计划"
- "dev-plan 太长了，归档已完成的部分"

### 前置校验（必须全部通过）

**校验 1：Phase 内所有 Task 状态**
- 检查目标 Phase 的每个 Task
- 必须全部标记为 ✅ 已完成
- 未完成的 Task 列出清单，阻止归档

**校验 1.5：Phase 标题行 Issue 状态**
- 检查 Phase 标题行的 `Issue:` 字段是否已填入编号（非 `#（待创建）`）
- 检查 `状态：` 字段是否为 `✅ 已完成`
- 未满足时提示：请先通过 glab-manage 关闭对应 Issue，状态会自动回写

**校验 2：GitLab Milestone 状态**
- 检查对应 Milestone 是否已关闭
- 未关闭时提示：请先在 GitLab 关闭 Milestone

**校验 3：后续 Phase 依赖引用**
- 扫描剩余 Phase 的所有 Task
- 检查"输入依赖"字段中是否引用了目标 Phase 的 Task 编号
- 存在依赖引用时列出具体 Task，提示先更新依赖

**校验 4：归档文件冲突**
- 检查 `docs/dev-plan-archive/phase-{N}.md` 是否已存在
- 已存在时提示"该 Phase 已归档，请确认是否重复操作"

### 执行步骤

全部校验通过后，按以下步骤执行（中途任一步骤失败则整体回滚）：

```
Step 1：创建归档目录
  mkdir -p docs/dev-plan-archive/

Step 2：生成归档文件 docs/dev-plan-archive/phase-{N}.md
  包含：Phase 元数据 + 完整 Phase 内容 + 所有 Task 和 Issue 编号

Step 3：从 dev-plan.md 删除目标 Phase 块
  精确删除从 "### Phase {N}:" 到下一个 "### Phase" 之前的全部内容

Step 4：更新 dev-plan.md 顶部已归档声明
  在文件头部 > 已归档：行追加：
  Phase {N}（{阶段名}）→ docs/dev-plan-archive/phase-{N}.md

Step 5：在 dev-plan.md 变更记录中追加一行
  | v{n} | {date} | Phase {N} 归档 → docs/dev-plan-archive/phase-{N}.md |

Step 6：输出归档报告
  ✅ Phase {N} 已归档
  归档文件：docs/dev-plan-archive/phase-{N}.md
  dev-plan.md 减少约 {N} 行
  当前活跃计划：Phase {M} 到 Phase {K}（共 {N} 个 Task）
```

详细指导见 [references/archive-guide.md](references/archive-guide.md)。

---

## 与其他 Skill 的集成

### glab-manage skill 的 Issue 编号查找

```
1. 先查 dev-plan.md 中的活跃 Phase（第 5 章开发计划）
   → 找到 → 读取 Task 的 Issue 字段

2. 未找到（Task 已归档）→
   查 dev-plan.md 顶部的"已归档 Phase 索引"表格
   → 根据 Issue 范围定位到对应 phase-N.md
   → 打开 phase-N.md，查找对应 Task 的 Issue 编号

3. 仍未找到 → 提示用户手动提供 Issue 编号
```

### git-commit skill 的上下文感知

```
1. 通过变更文件路径在 dev-plan.md 中匹配 Task
   → 匹配到 → 读取 Issue 字段，生成 Refs/Closes footer

2. 未匹配（Task 已归档）→
   查 dev-plan.md 顶部的"已归档 Phase 索引"表格
   → 根据 Issue 范围定位到对应 phase-N.md
   → 打开 phase-N.md，查找对应 Task 的 Issue 编号
   → 生成 footer，注明"（归档 Task）"

3. 完全未找到 → footer 留空，提示工程师手动填写
```

**关键点：** 其他 skill 无需修改，直接从 dev-plan.md 中的索引表查询即可

---

## 常见边缘情况

| 情况 | 处理方式 |
|------|----------|
| 用户只给了几句话描述 | 先输出骨架，标注 `{待补充}` 占位，询问缺失信息 |
| 已有代码库但无 PRD | 读取目录结构和 README，逆向推导现有架构后再规划 |
| Task 依赖关系复杂 | 在 Task 的"输入"字段注明前置 Task 编号，不画图 |
| 预估时间无法确定 | 写范围如 `4–8小时`，备注不确定因素 |
| dev-plan.md 超过 400 行 | 强烈建议执行 Phase 归档，提示用户具体操作 |
