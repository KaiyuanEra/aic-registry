# 反模式文档

> 收录编写 aic skill 时最常见的错误，每条附有修正示例。

---

## AP-01：description 过于模糊

**错误**
```yaml
description: Helps with database operations.
```

**问题：** 动词 "helps"、"assists"、"handles" 对 agent 没有语义价值。没有 `Use when`，agent 不知道何时触发。

**修正**
```yaml
description: >
  执行数据库迁移、优化慢查询、管理连接配置。
  Use when user mentions 数据库迁移, schema changes, or slow query optimization.
  Do NOT use for Redis/MongoDB 或应用层 ORM 代码编写。
```

---

## AP-02：description 只描述实现，不描述触发场景

**错误**
```yaml
description: Uses pdfplumber to extract text from PDF files.
```

**问题：** 工程师不会说"用 pdfplumber 处理 PDF"，他们会说"帮我解析这个 PDF"。description 应该匹配用户的提问方式，而不是实现细节。

**修正**
```yaml
description: >
  从 PDF 中提取文本、表格、表单数据。
  Use when user asks about PDFs, mentions .pdf files, needs form filling,
  or says "帮我解析这个文件" / "提取 PDF 内容".
  Do NOT use for图片 OCR 或 Word/Excel 文件处理。
```

---

## AP-03：缺少 version 字段

**错误**
```yaml
---
name: log-analyzer
description: 分析日志文件...
tags: [ops]
---
```

**问题：** aic 强制要求 `version` 字段。缺失时 `aic install` 会拒绝安装并报错。

**修正**
```yaml
---
name: log-analyzer
version: 1.0.0
description: 分析日志文件...
tags: [ops]
---
```

---

## AP-04：env-required: true 但缺少 env-vars 声明

**错误**
```yaml
---
name: database-ops
version: 1.0.0
description: ...
env-required: true
# 忘记声明 env-vars
---

连接到 {{DB_HOST}}，用户 {{DB_USER}}
```

**问题：** `validate.sh` 会报错。缺少 `env-vars` 时，skill 无法说明需要哪些变量，也无法在 `aic env check` 中提示工程师补充。

**修正**
```yaml
---
name: database-ops
version: 1.0.0
description: ...
env-required: true
env-vars:
  - name: DB_HOST
    description: 数据库主机地址
    required: true
    target: skill
  - name: DB_USER
    description: 数据库用户名
    required: true
    target: skill
---
```

---

## AP-04B：变量名格式错误或重复

**错误**
```yaml
env-vars:
  - name: api_key
    description: API key
    required: true
    target: skill
  - name: API-KEY
    description: Duplicate API key alias
    required: true
    target: skill
  - name: api_key
    description: Repeated variable
    required: true
    target: skill
```

**问题：** 变量名必须匹配 `^[A-Z][A-Z0-9_]*$`，区分大小写，且同一声明中不得重复。

**修正**
```yaml
env-vars:
  - name: API_KEY
    description: API key
    required: true
    target: skill
```

---

## AP-05：正文中写入真实的敏感值

**错误**
```markdown
# 数据库操作规范
连接信息：
- Host: 10.0.1.100
- Password: prod_secret_2024
```

**问题：** SKILL.md 会提交到 GitLab 公司仓库，任何有权限的人都能看到。真实值属于高危泄露风险。

**修正**
```markdown
# 数据库操作规范
环境变量说明：
- `DB_HOST`：数据库连接入口，缺失时停止并提示用户补齐
- `DB_PASSWORD`：数据库密码，缺失时停止并提示用户补齐
```

---

## AP-06：目录名与 name 字段不一致

**错误**
```
skills/common/pdf_processing/   ← 下划线
    SKILL.md  → name: pdf-processing   ← 连字符
```

**问题：** aic 通过目录名加载 skill，名称不一致时 skill 不会被正确识别。

**修正规则：** 目录名和 `name` 字段必须**完全一致**，统一使用**小写连字符**（kebab-case）：
```
skills/common/pdf-processing/
    SKILL.md  → name: pdf-processing  ✅
```

---

## AP-07：SKILL.md 正文超过 500 行

**错误：** 把完整的操作手册、API 文档、示例集都写进 SKILL.md 正文。

**问题：** 每次 skill 被触发，整个正文都会加载进 context window。500 行约 5000 tokens，再长会显著消耗 agent 的可用 context，影响其他 skill 和对话内容。

**修正原则：**
- SKILL.md 是「作弊单」（cheat sheet），不是完整文档
- 参考内容、详细规范、示例集移到 `references/` 目录
- 正文只保留核心流程和最关键的判断依据

```
skill/
├── SKILL.md              ← 核心流程，< 500 行
└── references/
    ├── api-reference.md  ← 详细 API 文档，按需加载
    └── examples.md       ← 完整示例集，按需加载
```

---

## AP-08：references/ 中存在嵌套引用链

**错误**
```markdown
<!-- SKILL.md -->
详见 [规范A](references/spec-a.md)

<!-- references/spec-a.md -->
更多细节见 [规范B](references/spec-b.md)

<!-- references/spec-b.md -->
另见 [规范C](references/spec-c.md)
```

**问题：** Agent 需要多次读取才能获得完整信息，增加 context 消耗，且引用链容易断裂。

**修正：** references/ 中的文件应该自包含，引用深度不超过一层。

---

## AP-09：description 与相邻 skill 边界不清

**错误场景：** 项目中同时有 `database-ops`（操作规范）和 `database-migration`（专门处理迁移），但两者 description 都写了"执行数据库迁移"，导致 agent 随机触发其中一个。

**修正：** 在两个 skill 的 description 中互相排除：

```yaml
# database-ops 的 description
description: >
  数据库日常操作规范：查询优化、连接配置、索引管理。
  Use when optimizing queries, managing connections, or tuning database performance.
  Do NOT use for schema migrations（迁移请用 database-migration skill）.

# database-migration 的 description
description: >
  执行数据库 Schema 迁移，管理迁移脚本版本。
  Use when running migrations, writing migration scripts, or rolling back schema changes.
  Do NOT use for query optimization or routine database operations.
```

---

## AP-10：适配层文件不完整

**错误：** 创建了 `adapters/claude/SKILL.md`，但只写了 `allowed-tools` frontmatter，正文为空。

**问题：** 适配层文件是完整独立文件，不做字段合并。空正文意味着 Claude Code 读到的 skill 没有任何指令。

**修正：** 适配层文件必须包含完整的 frontmatter + 正文。可以从主 SKILL.md 复制正文再添加 Claude 专有字段：

```yaml
---
name: database-ops
version: 1.2.0
description: >   # 与主 SKILL.md 保持一致
  ...
allowed-tools: [Bash, Read]   # Claude Code 专有字段
---

# Database Ops（Claude Code 版本）
[完整正文，与主 SKILL.md 相同或有针对性修改]
```
