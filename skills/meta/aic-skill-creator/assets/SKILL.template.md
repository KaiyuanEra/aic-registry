---
# SKILL.md 标准模板
# 使用说明：
#   1. 将此文件复制到 skills/<category>/<skill-name>/SKILL.md
#   2. 目录名必须与 name 字段完全一致（小写连字符）
#   3. 删除所有注释行（# 开头）后提交 MR
#   4. 运行 validate.sh 和 description-score.sh 验证
#
# 分类参考：
#   skills/common/   → 通用 skill，与业务无关（git、docker、code-review 等）
#   skills/domain/   → 业务域 skill（database-ops、backend-api、frontend-build 等）

name: <skill-name>           # 与目录名完全一致，小写连字符（kebab-case）
version: 1.0.0               # 必填，语义化版本；修复 → patch，新增 → minor，重构 → major
description: >
  # 必须中英混写：中文覆盖口语触发词，英文覆盖技术术语
  # 公式：[中文功能描述]. Use when [英文技术场景],
  #       or when user mentions [中文口语关键词], [英文命令].
  #       Do NOT use for [排除场景].
  # 示例：
  #   执行数据库迁移、优化慢查询、管理连接配置。
  #   Use when running schema migrations or tuning query performance,
  #   or when user mentions 数据库迁移, 慢查询, 连接跑不通, or db migrate.
  #   Do NOT use for Redis/MongoDB 或应用层 ORM 代码编写。
  <在此填写 description>
tags: [<tag1>, <tag2>]       # 用于 aic list 过滤，2–4 个标签

# ── env-required（按需启用）──────────────────────────────
# 如果 skill 不需要注入本地变量，删除以下所有 env 相关行
env-required: false

# env-required: true 时取消注释并填写：
# env-required: true
# env-vars:
#   - name: DB_HOST
#     description: 数据库主机地址（如 10.0.1.100）
#     required: true
#     target: skill
#   - name: DB_USER
#     description: 数据库用户名
#     required: true
#     default: ""
#     target: skill
#   - name: DB_PASSWORD
#     description: 数据库密码
#     required: true
#     target: skill
---

# <Skill 名称>

<!-- 一句话说明这个 skill 的核心价值，供 aic list 详情面板展示 -->

---

## 使用场景

**适用：**
- <场景一>
- <场景二>

**不适用：**
- <排除场景一>（应使用 <other-skill> skill）

---

## 前置知识

<!-- 列出 agent 需要了解的关键文件、配置入口或核心概念 -->
<!-- 控制在 5–10 条，保持精简 -->

- <关键文件或配置>：`<路径或说明>`
- <核心概念>：<一句话解释>

---

## 工作流程

<!-- 用命令式步骤描述，每步说明输入和产出 -->

1. **<步骤一>** — <操作说明>
   ```bash
   <示例命令>
   ```
   产出：<产出物说明>

2. **<步骤二>** — <操作说明>

3. **<步骤三>** — <操作说明>

---

## 常见边缘情况

<!-- 列出 agent 容易踩坑的地方和对应处理方式 -->

| 情况 | 处理方式 |
|------|----------|
| <边缘情况一> | <处理方式> |
| <边缘情况二> | <处理方式> |

---

## 示例

<!-- 具体的输入/输出示例比抽象描述更有效 -->

**输入：** <用户请求描述>

**操作：**
```bash
<具体命令或步骤>
```

**产出：** <预期结果>

---

<!-- ── 可选区块，按需保留或删除 ───────────────────── -->

## 参考文档

<!-- 仅在有 references/ 目录文件时使用 -->
<!-- 保持一层引用深度，不做嵌套引用 -->

- [<文档名>](references/<file>.md) — <一句话说明用途>

<!-- ─────────────────────────────────────────────── -->
