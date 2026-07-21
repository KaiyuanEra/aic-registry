---
name: aic-skill-creator
version: 2.1.0
description: >
  编写、设计、改进 aic 内部 SKILL.md 文件。
  Use when 创建新 skill、从零写 SKILL.md、优化 skill 的 description 触发质量、
  设计 skill 目录结构，or when user mentions 写 skill、skill 怎么写、
  description 不触发、skill 放哪个目录、env-required 怎么配、适配层怎么加。
  Do NOT use for aic install/remove/sync 命令、管理已安装的 skill，
  或编写与 skill 无关的业务代码文档。
tags: [skill-authoring, meta, aic]
env-required: false
---

# aic Skill Creator

公司内部 aic skill 编写向导。遵循 **TDD → Draft → Validate → Review → Ship** 循环。

---

## 核心原则（先读，再动手）

1. **description 是唯一触发机制** — Claude Code 不用正则或分类器，只把所有 skill 的 `name + description` 聚合成 meta-tool 传给 agent。描述写差了，skill 永远不会被触发。
2. **Progressive Disclosure** — SKILL.md 是「作弊单」，不是完整文档。重细节放 `references/`，按需加载。
3. **aic 约束** — 所有 skill 必须有 `version`（语义化）；需要本地配置时声明 `env-required: true` 和 `env-vars`，绝不写真实值。
4. **变量名是硬约束** — Skill 与 Context 统一使用 `^[A-Z][A-Z0-9_]*$`；变量名区分大小写，禁止小写字母、连字符、点号、空格、数字或下划线开头，同一声明中不得重复。

---

## 工作流

### Step 0 — 先写测试用例（TDD）

在动手写 SKILL.md 之前，列出触发场景：

```
✅ 应该触发（正例）
- "帮我写一个处理 Kafka 消费的 skill"
- "我要创建一个数据库操作的 SKILL.md"
- "这个 skill 的 description 怎么写更好"

❌ 不应该触发（反例）
- "aic install kafka-ops"
- "查看已安装的 skill 列表"
- "帮我写 Kafka 消费者代码"（非 skill 编写任务）
```

用测试用例驱动 description 的写法，而不是先写 description 再想测试。

---

### Step 1 — 创建目录结构

```bash
# 在 skills/ 下创建（common/ 或 domain/ 取决于业务相关性）
mkdir -p skills/common/<skill-name>/{references,scripts,assets}
cp assets/SKILL.template.md skills/common/<skill-name>/SKILL.md
```

目录名必须与 frontmatter `name` 字段**完全一致**（小写连字符）。

---

### Step 2 — 填写 frontmatter

```yaml
---
name: <skill-name>           # 与目录名完全一致
version: 1.0.0               # 必填，语义化版本
description: >               # 见 Step 3
  ...
tags: [<tag1>, <tag2>]       # 便于 aic list 过滤
env-required: false          # 若需要注入本地变量则改为 true
# env-required: true 时必须补充：
# env-vars:
#   - name: DB_HOST
#     description: 数据库主机
#     required: true
#     target: skill
---
```

**变量名必须匹配 `^[A-Z][A-Z0-9_]*$`。** 合法：`API_KEY`、`API_BASE_URL`、`AIC_AVAILABLE_CLI_TOOLS`、`MODEL_V2_ENDPOINT`。非法：`api_key`、`2FA_TOKEN`、`API-KEY`、`API.KEY`、`_API_KEY`。同一 `env-vars` 中不得重复，且名称区分大小写。完整规则见 [aic 特有规范](references/skm-spec.md)。

---

### Step 3 — 用模板写 description

套用此公式，然后用 Step 0 的测试用例验证：

```
[动词短语，说明核心功能].
Use when [正例场景1], [正例场景2], or when user mentions [关键词].
Do NOT use for [排除场景1] or [排除场景2].
```

运行评分脚本检查质量：

```bash
scripts/description-score.sh skills/<category>/<skill-name>/SKILL.md
```

分数 < 60 时重写 description，见 [description 模式库](references/description-patterns.md)。

---

### Step 4 — 编写正文

正文结构（参考，非强制）：

```markdown
## 使用场景
何时用 / 何时不用

## 前置知识 / 核心对象
关键文件、配置入口、重要概念

## 工作流程
1. 步骤一 → 产出物
2. 步骤二 → 产出物

## 常见边缘情况
容易出错的地方和对应处理

## 示例
具体输入 / 输出
```

**长度控制：** 正文 < 500 行（约 5000 tokens）。更长的内容拆到 `references/`。

#### env-required skill 正文规范

`env-required: true` 时，不要把真实值或渲染后的值写进 `SKILL.md`。

**关键约束：**

- `env-vars` 中声明的变量，必须在正文或脚本说明中被明确引用其**用途与缺失处理**。
- 不得要求 agent 依赖记忆值、上一个项目的值或猜测值。
- 任何文件中**禁止出现**真实 IP、域名、密码、token——包括 `references/` 和 `scripts/`。

```yaml
# 正确：说明用途，不写真实值
DB_HOST 是数据库连接入口；缺失时停止并提示用户补齐

# 错误：硬编码真实值
Host: 10.0.1.100
```

---

### Step 5 — 结构校验

```bash
scripts/validate.sh skills/<category>/<skill-name>/SKILL.md
```

所有检查项必须通过才能进入 review。常见错误见 [反模式文档](references/anti-patterns.md)。

---

### Step 6 — 三工具兼容检查

| 场景 | 处理方式 |
|------|----------|
| skill 对三工具行为完全一致 | 仅需 `.agents/skills/` 链接，无需适配层 |
| Claude Code 需要 `allowed-tools` 等专有字段 | 在 `adapters/claude/SKILL.md` 中添加 |
| 某工具有特殊 UI 元数据需求 | 见 [兼容性矩阵](references/compatibility-matrix.md) |

```bash
# 确认三工具都能读取（需在安装了 aic 的项目中执行）
scripts/self-test.sh <skill-name>
```

---

### Step 7 — 提交 MR

```bash
# 确保 version 已在 SKILL.md frontmatter 中设置
# CI 会自动更新 skills/index.yaml
git add skills/<category>/<skill-name>/
git commit -m "feat(skill): add <skill-name> v1.0.0"
# 推送并在 GitLab 创建 MR，指向 dev 分支
```

MR 合并后，工程师可通过 `aic install <skill-name>` 安装。

---

## 快速参考

| 我需要... | 看这里 |
|-----------|--------|
| description 怎么写才能触发 | [description 模式库](references/description-patterns.md) |
| 我的写法有什么常见错误 | [反模式文档](references/anti-patterns.md) |
| env-required / 版本 / 适配层规范 | [aic 特有规范](references/aic-spec.md) |
| 三工具路径和兼容性 | [兼容性矩阵](references/compatibility-matrix.md) |
| 从空白模板开始 | [assets/SKILL.template.md](assets/SKILL.template.md) |
