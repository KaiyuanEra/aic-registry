# description 写法模式库

> description 是 skill 触发的**唯一机制**。
> Claude Code 将所有 skill 的 `name + description` 聚合为 meta-tool 传给 agent，
> 纯靠 LLM forward pass 语义匹配，无正则、无分类器。
>
> **aic 场景特别说明：** 公司工程师主要用中文提问，LLM 有跨语言语义理解能力，
> 但口语化中文（"帮我整个 skill"、"跑不起来"）与纯英文 description 的语义距离
> 比正式中文更远。**所有 skill 的 description 必须中英混写**，用中文覆盖口语触发词，
> 用英文覆盖技术术语和命令行关键词。

---

## 核心公式

```
[动词短语，描述核心功能].
Use when [正例场景1], [正例场景2], or when user mentions [关键词列表].
Do NOT use for [排除场景] or [容易混淆的相邻场景].
```

**三段缺一不可：**
- 功能段 → 告诉 agent 这个 skill 能做什么
- `Use when` 段 → 告诉 agent 什么时候应该触发（**必须含中文口语关键词**）
- `Do NOT use for` 段 → 防止误触发，与相邻 skill 划定边界

**中英混写是强制要求，不是建议。** 标准模板：

```yaml
description: >
  <中文功能描述>.
  Use when <英文技术场景>, <英文技术场景>,
  or when user mentions <中文口语关键词>, <中文关键词>, or <英文命令/术语>.
  Do NOT use for <中文排除场景> or <英文排除场景>.
```

---

## 模式一：动作优先型（最常用）

适用于功能单一、动作明确的 skill。

```yaml
description: >
  执行数据库迁移、优化慢查询、管理连接配置。
  Use when working with MySQL/PostgreSQL schema changes, running migrations,
  or when user mentions 数据库迁移, 慢查询, 连接池, or database performance.
  Do NOT use for Redis, MongoDB, or writing application-layer ORM code.
```

**要点：**
- 动词放最前（执行、生成、分析、管理）
- `Use when` 里混用中英文关键词，覆盖工程师实际输入习惯

---

## 模式二：场景枚举型

适用于 skill 覆盖多个独立场景，每个场景都值得单独说明。

```yaml
description: >
  Docker 容器操作规范。
  Use when: (1) 编写或审查 Dockerfile, (2) 调试容器启动失败,
  (3) 配置 docker-compose 多服务, (4) 分析镜像体积.
  Do NOT use for Kubernetes 部署或 CI/CD 流水线配置。
```

**要点：**
- 用编号列出场景，结构清晰
- 每个场景用动名词短语

---

## 模式三：角色视角型

适用于 skill 是某个角色或阶段专有的。

```yaml
description: >
  Code review 规范，面向 MR 审查者。
  Use when reviewing a pull request, providing code review comments,
  checking MR checklist, or when user asks "帮我看看这个 MR" / "review 一下".
  Do NOT use for writing new code or fixing bugs (not in review context).
```

**要点：**
- 明确角色（审查者 vs 开发者），减少跨角色误触发

---

## 模式四：否定优先型

适用于 skill 名称容易与其他常见任务混淆的情况。先写排除，让 agent 主动识别边界。

```yaml
description: >
  编写新的 aic SKILL.md 文件。
  Do NOT use for: aic install/remove/sync 命令, 管理已安装的 skill, 或编写非 skill 的文档。
  Use when creating a new skill from scratch, improving an existing skill's description trigger,
  or designing the structure of a SKILL.md for aic compatibility.
```

**要点：**
- 当误触发风险高时，`Do NOT use for` 放最前
- 适合 meta-skill（skill 关于 skill 本身）

---

## 模式五：关键词注入型

适用于用户提问时高度依赖特定中文术语的场景。

```yaml
description: >
  前端构建流水线配置与调试。
  Use when user mentions 构建失败, webpack 报错, vite 配置, 热更新不生效,
  打包体积过大, tree shaking, 或 "前端跑不起来".
  Do NOT use for 后端 API 开发或数据库操作。
```

**要点：**
- 收集工程师实际使用的俗语和口语化表达
- 引号内的词组更接近真实触发词

---

## 中英文混写规范

公司工程师日常中英混用，description 应同时覆盖两种表达：

```yaml
# ✅ 好：两种语言都覆盖
Use when user mentions 数据库迁移, schema migration, or running `db migrate`.

# ❌ 差：只有英文，中文提问时可能不触发
Use when user mentions database migration or schema changes.
```

---

## description 长度建议

| 场景 | 建议字数 |
|------|----------|
| 功能单一，边界清晰 | 30–60 词 |
| 多场景，需要列举 | 60–100 词 |
| 与多个 skill 存在边界模糊 | 100–150 词（加强排除段） |
| 超过 150 词 | 重新审视 skill 是否职责过宽，考虑拆分 |

---

## description 自检清单

写完后逐项确认：

- [ ] 以动词或功能名词开头（不以"This skill"或"A tool that"开头）
- [ ] 包含 `Use when` + 至少 2 个正例场景
- [ ] 包含 `Do NOT use for` + 至少 1 个排除场景
- [ ] 覆盖了中文和英文关键词
- [ ] 通过了 `scripts/description-score.sh` 评分（≥ 60 分）
- [ ] 没有使用模糊动词（help、assist、handle、deal with）

---

## 反面示例对照

```yaml
# ❌ 模糊功能，无触发场景
description: Helps with database operations.

# ❌ 只写功能，没有触发语境
description: Processes and analyzes log files using grep and awk.

# ❌ 过于宽泛，会误触发
description: >
  Assists with backend development tasks.
  Use when doing backend work.

# ✅ 对照改写
description: >
  分析应用日志、提取错误模式、统计请求量趋势。
  Use when debugging production errors, analyzing access logs,
  or when user mentions 日志分析, 错误追踪, log grep, or "帮我看看日志".
  Do NOT use for structured database queries or metrics dashboards.
```
