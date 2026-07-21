# aic 特有规范

> 本文档是 SKILL.md 标准规范的 aic 扩展层。
> 标准规范（name / description / Progressive Disclosure）见主 SKILL.md 正文。

---

## 1. 版本字段（必填）

aic 要求每个 skill 必须有 `version` 字段，符合语义化版本（SemVer）：

```yaml
---
name: database-ops
version: 1.2.0        # 必填，格式：MAJOR.MINOR.PATCH
---
```

**版本与 Git tag 对应关系：**

- `aic install database-ops` 安装时，aic 从 `skills/index.yaml` 读取最新版本
- `aic install database-ops@1.2.0` 安装时，aic 检出对应 Git tag `skills/database-ops@1.2.0`
- **无 version 字段或无对应 Git tag 的 skill 拒绝安装**

**版本升级规范：**

| 变更类型 | 版本变更 | 示例 |
|----------|----------|------|
| 修复 description 误触发、错别字 | PATCH | 1.0.0 → 1.0.1 |
| 新增内容、扩展使用场景 | MINOR | 1.0.0 → 1.1.0 |
| 重写 description、重构结构、破坏性变更 | MAJOR | 1.0.0 → 2.0.0 |

---

## 2. env-required 设计

### 何时使用

skill 正文中需要引用本地敏感信息时（数据库连接、API Key、内部服务地址等）才设置 `env-required: true`。

### 完整 frontmatter 示例

```yaml
---
name: database-ops-with-creds
version: 1.0.0
description: >
  执行数据库迁移、查询优化、连接配置。
  Use when working with MySQL/PostgreSQL operations, schema migrations, or query tuning.
  Do NOT use for Redis, MongoDB, or non-relational databases.
tags: [database, backend]
env-required: true
env-vars:
  - name: DB_HOST
    description: 数据库主机地址（如 10.0.1.100）
    required: true
    target: skill
  - name: DB_USER
    description: 数据库用户名
    required: true
    default: ""
    target: skill
  - name: DB_PASSWORD
    description: 数据库密码
    required: true
    target: skill
---
```

### 变量读取约定

正文不要写真实值，也不要依赖预渲染副本。`env-required` skill 应在正文中明确声明变量用途与缺失处理：

```markdown
若 `DB_HOST` / `DB_USER` 缺失，必须停止并提示用户运行 `aic env add` 或 `aic env edit` 补齐。
```

> **推荐做法：**
> - 在 `SKILL.md` 中写明变量用途、缺失处理和禁止猜值的约束
> - 禁止在任何文件中写入真实 IP、域名、token、密码——包括 `references/`、`scripts/`

### env-vars 声明使用要求

`env-vars` 中声明的变量，必须在 `SKILL.md` 正文、reference 或脚本说明中明确其用途、读取来源和缺失时的处理方式。

### 变量名硬性规则

Skill 与 Context 使用完全相同的变量名规则：

```text
^[A-Z][A-Z0-9_]*$
```

- 必须以大写字母开头。
- 后续只能使用大写字母、数字和下划线。
- 区分大小写。
- 不允许小写字母、连字符、点号或空格。
- 不允许数字或下划线开头。
- 同一 `env-vars` 声明中不得重复。

合法示例：

```text
API_KEY
API_BASE_URL
AIC_AVAILABLE_CLI_TOOLS
MODEL_V2_ENDPOINT
```

非法示例：

```text
api_key
2FA_TOKEN
API-KEY
API.KEY
_API_KEY
```

### env-required skill 的测试注意事项

`scripts/validate.sh` 至少应检查：
- `env-required: true` 时 `env-vars` 字段不能为空
- 所有变量名符合 `^[A-Z][A-Z0-9_]*$`，且不存在重复声明
- 缺失变量时要求停止并提示用户补齐
- 任何 `.md` 文件中**不应出现**疑似真实 IP、密码、token 的硬编码字符串

---

## 3. 适配层（Adapter Layer）

### 何时需要适配层

当 skill 对不同 AI 工具需要不同内容时，在 `adapters/` 目录创建工具专有版本：

```
database-ops/
├── SKILL.md                    ← 三工具通用版本（放在 .agents/skills/）
└── adapters/
    ├── claude/
    │   └── SKILL.md            ← Claude Code 专有版本（放在 .claude/skills/）
    └── codex/
        └── SKILL.md            ← Codex 专有版本
```

### 适配层的常见使用场景

| 场景 | 适配层内容 |
|------|-----------|
| Claude Code 需要 `allowed-tools` 控制 | 在 `adapters/claude/SKILL.md` frontmatter 添加 `allowed-tools: [Bash, Read]` |
| Codex 需要 `agents/openai.yaml` 元数据 | 在 `adapters/codex/` 添加 `agents/openai.yaml` |
| 某工具有不同的工作流步骤 | 适配层覆盖正文中的该部分 |

### 适配层 frontmatter 继承规则

适配层 SKILL.md 应保持与主 SKILL.md 相同的 `name` 和 `version`，只修改差异部分。aic 不做字段合并，适配层文件是完整独立文件。

### 何时**不需要**适配层

大多数 skill 不需要适配层。如果差异只是措辞，统一写在主 SKILL.md 中即可。
适配层增加维护成本，只在有明确的工具专有需求时使用。

---

## 4. skills/index.yaml 维护规范

`index.yaml` 由 CI 自动维护，**不需要手动编辑**。触发 CI 更新的条件：

- 向 `dev` 分支推送了新的 `skills/<category>/<skill-name>/SKILL.md`
- 创建了格式为 `skills/<skill-name>@<version>` 的 Git tag

如果需要发布新版本：
1. 确认 `SKILL.md` 中 `version` 已更新
2. 创建对应 tag：`git tag skills/database-ops@1.3.0`
3. 推送 tag：`git push origin skills/database-ops@1.3.0`
4. CI 自动更新 `index.yaml`

---

## 5. .aicrc 中的 skill 声明

当工程师在自己项目中安装 skill 后，`.aicrc` 会自动记录：

```toml
[[skills]]
name         = "database-ops"
version      = "1.2.0"
env_required = true    # 提醒其他协作者此 skill 需要配置 ~/.aic-env
```

skill 作者无需关心 `.aicrc`，这由 aic 自动维护。但应在 skill 的 README 或 SKILL.md 中说明 env-required skill 的变量配置方法，方便新成员入职时参考。
