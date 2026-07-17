---
name: readme-doc
version: 1.0.0
description: >
  为项目生成或更新专业的 README.md，包含徽章、项目概述、技术栈、架构、项目结构、部署使用、许可证六大模块。
  Use when creating or rewriting a README, documenting a project for the first time,
  or when user mentions 写 README、生成文档、项目介绍、README.md、项目说明、
  补充文档、更新 README、写个介绍、项目文档、readme 怎么写。
  Do NOT use for API 接口文档、代码注释、CHANGELOG、dev-plan 开发计划，
  或只需要更新某一个小节而非整体 README 的场景。
tags: [docs, readme, dev-workflow]
env-required: false
---

# readme-doc

为项目生成结构完整、视觉专业的 `README.md`，覆盖六大模块。

**设计原则：** 先读懂项目，再动笔——从代码和配置文件中提取真实信息，不编造内容。

---

## 信息采集（生成前必做）

按优先级依次读取，提取项目元数据：

```
① go.mod / package.json / pyproject.toml / Cargo.toml
   → 项目名、语言版本、主要依赖

② 目录结构（ls -1 / tree -L 2）
   → 模块划分、入口文件、配置文件位置

③ Makefile / Dockerfile / docker-compose.yml
   → 构建命令、部署方式、环境要求

④ 现有 README.md（如存在）
   → 保留已有准确内容，只补充/重写缺失部分

⑤ 主要源码入口（cmd/main.go、src/index.ts 等）
   → 核心功能描述、CLI flags、API 路由
```

采集完成后，向用户确认：
- 项目一句话描述（如现有描述不够准确）
- License 类型（MIT / Apache-2.0 / 私有等）
- 联系方式（邮箱 / GitLab 用户名）

---

## 徽章选择规则

**核心原则：徽章必须与项目实际技术栈一一对应，不堆砌，不使用示例中没有用到的技术。**

步骤：
1. 从信息采集阶段确认的技术栈列表出发，逐项匹配徽章
2. 在 [references/badges.md](references/badges.md) 中查找对应徽章代码
3. 找不到时，去 https://simpleicons.org/ 搜索技术名获取 logo slug 和品牌色，自行构造
4. 徽章顺序：语言/运行时 → 框架 → 数据库 → 消息队列 → 基础设施 → License

根据采集到的技术栈，从下方选取对应徽章，**只放实际用到的**：

```markdown
<!-- 语言 / 运行时 -->
[![Go Version](https://img.shields.io/badge/Go-1.24+-00ADD8?style=flat&logo=go)](https://go.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-20+-339933?style=flat&logo=node.js)](https://nodejs.org/)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat&logo=python)](https://python.org/)
[![Rust](https://img.shields.io/badge/Rust-1.75+-000000?style=flat&logo=rust)](https://rust-lang.org/)

<!-- 数据库 -->
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?style=flat&logo=postgresql)](https://postgresql.org/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=flat&logo=mysql)](https://mysql.com/)
[![SQLite](https://img.shields.io/badge/SQLite-3.x-003B57?style=flat&logo=sqlite)](https://www.sqlite.org/)
[![Redis](https://img.shields.io/badge/Redis-7.x-DC382D?style=flat&logo=redis)](https://redis.io/)
[![MongoDB](https://img.shields.io/badge/MongoDB-7.x-47A248?style=flat&logo=mongodb)](https://mongodb.com/)

<!-- 框架 -->
[![Gin](https://img.shields.io/badge/Gin-1.x-00ADD8?style=flat&logo=go)](https://gin-gonic.com/)
[![React](https://img.shields.io/badge/React-18+-61DAFB?style=flat&logo=react)](https://react.dev/)
[![Vue](https://img.shields.io/badge/Vue-3.x-4FC08D?style=flat&logo=vue.js)](https://vuejs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=flat&logo=fastapi)](https://fastapi.tiangolo.com/)

<!-- 基础设施 -->
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?style=flat&logo=docker)](https://docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-ready-326CE5?style=flat&logo=kubernetes)](https://kubernetes.io/)
[![GitLab CI](https://img.shields.io/badge/GitLab_CI-passing-FC6D26?style=flat&logo=gitlab)](https://gitlab.com/)

<!-- 许可证（必选一个） -->
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![License](https://img.shields.io/badge/License-Private-red.svg)](LICENSE)
```

更多徽章见 [references/badges.md](references/badges.md)。

---

## README 结构模板

生成时严格按以下顺序和格式输出：

```markdown
<徽章行（空格分隔，一行内）>

# <项目名>

> <一句话描述，说明项目是什么、解决什么问题>

---

## 项目概述 (Project Overview)

<2-4 段，说明：背景与动机、核心功能列表（bullet）、适用场景>

---

## 技术栈 (Technology Stack)

| 分类 | 技术 | 版本 | 说明 |
|------|------|------|------|
| 语言 | Go | 1.24+ | ... |
| 数据库 | ... | ... | ... |
| ... | ... | ... | ... |

---

## 整体架构设计 (Architecture)

<架构描述，2-3 段 + ASCII 图或分层说明>

示例（按实际情况选用）：

### 分层架构
\`\`\`
┌─────────────────────────────────┐
│           CLI / API Layer        │
├─────────────────────────────────┤
│         Business Logic           │
├─────────────────────────────────┤
│      Repository / Storage        │
└─────────────────────────────────┘
\`\`\`

### 数据流
\`\`\`
用户请求 → 路由层 → 业务层 → 数据层 → 响应
\`\`\`

---

## 项目结构 (Project Structure)

\`\`\`
<项目名>/
├── <目录1>/          # 说明
├── <目录2>/          # 说明
│   ├── <子目录>/     # 说明
│   └── ...
└── ...
\`\`\`

> 只展示 2 层深度，超过 10 个顶层条目时折叠次要目录。

---

## 部署和使用 (Deployment & Usage)

### 前置要求

- <运行时> <版本>+
- <其他依赖>

### 快速开始

\`\`\`bash
# 1. 克隆仓库
git clone <repo-url>
cd <project>

# 2. 安装依赖 / 构建
<install/build command>

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env 填入必要配置

# 4. 启动
<start command>
\`\`\`

### 配置说明

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `<VAR>` | ✅ | — | ... |
| `<VAR>` | ❌ | `<default>` | ... |

### 常用命令

\`\`\`bash
<command1>   # 说明
<command2>   # 说明
\`\`\`

---

## 许可证与联系方式

本项目基于 [<License>](LICENSE) 协议开源。

如有问题或建议，欢迎通过以下方式联系：

- GitLab Issues：[提交 Issue](<repo-url>/-/issues)
- 邮箱：<email>（可选）
```

---

## 写作规范

- **语言**：中英文双语标题（`## 项目概述 (Project Overview)`），正文用中文
- **徽章**：只放实际用到的技术，不堆砌
- **架构图**：优先用 ASCII art，保持在 20 行以内；复杂系统可用 Mermaid
- **项目结构**：只展示 2 层，加简短注释，不列出所有文件
- **命令示例**：必须是可直接运行的真实命令，不写伪代码
- **配置表格**：从 `.env.example`、`config.go`、`README` 现有内容中提取，不猜测

---

## 常见边缘情况

| 情况 | 处理方式 |
|------|----------|
| 项目无 License 文件 | 询问用户选择，默认写 MIT；提示创建 LICENSE 文件 |
| 已有 README 内容较完整 | 逐节对比，只补充缺失模块，不覆盖已有准确内容 |
| 无 .env.example | 从代码中扫描 `os.Getenv` / `viper` / `env:` tag 提取变量 |
| 纯库项目（无 CLI/服务） | 部署章节改为「安装与集成」，重点写 import 和 API 示例 |
| Monorepo | 顶层 README 写整体概述，各子模块目录下分别生成子 README |
| 私有项目 | License 徽章用 Private，去掉 Issues 链接，联系方式可留空 |
