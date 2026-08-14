[English](./README.md) | **简体中文**

# aic-registry

> **aic 的公共 Registry 与内容仓库。**
> aic 本身是一个本地优先的 AI 编程配置管理工具（闭源、个人免费），通过本仓库的 Release 分发二进制包。

- GitHub（海外）：https://github.com/KaiyuanEra/aic-registry
- Gitee（国内主）：https://gitee.com/KaiyuanEra/aic-registry

## 1. aic 是什么

aic 是一个**本地优先的 AI 编程配置管理工具**，以一体化 TUI 为主入口。在一个终端界面内统一管理 Claude Code、Codex CLI、Gemini CLI、OpenCode 的 Skills、Context、MCP server、环境变量、权限和 Provider，并与你的开发工具终端无缝衔接。

- **TUI 是主入口**：Skills / Contexts / MCP / Ops / Env / Permission / Provider 共 7 个面板。
- **本地优先**：项目配置写在 `<project>/.aic/`，用户配置写在 `~/.aic/`，敏感 env 值不入数据库。
- **可携带**：团队约定随项目走，新成员克隆即可 `aic sync` 还原整套配置。
- **克制**：不引入账号、云同步、计费、付费墙。

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/tui-hero-dark.webp">
  <img src="assets/tui-hero-light.webp" alt="aic TUI 主界面：Skills / Contexts / MCP / Ops / Env / Permission / Provider 七面板" width="800">
</picture>

完整介绍、概念、快捷键参考与故障排查请访问 **aic 文档站**：

> 网站地址待 Cloudflare Pages 部署后回填。

## 2. 安装

### macOS / Linux

从 Release 页面下载对应平台的压缩包，解压到 PATH 即可：

- GitHub Releases（海外）：https://github.com/KaiyuanEra/aic-registry/releases
- Gitee Releases（国内）：https://gitee.com/KaiyuanEra/aic-registry/releases

```bash
# 示例：macOS arm64
tar -xzf aic_<version>_darwin_arm64.tar.gz
sudo mv aic /usr/local/bin/
aic --version
```

> 一键安装脚本（支持 Gitee / GitHub 镜像切换与版本指定）正在准备中。

### Windows（Beta）

Windows 当前是 Beta 状态：暂不支持一键安装与 `tar.gz` 发布包。在没有管理员权限或开发者模式时，skill 分发默认走受管目录 copy sync，不会创建符号链接。

### 首次使用

在**业务项目根目录**运行：

```bash
aic init
aic
```

`aic` 会进入 TUI。在 TUI 内可以安装技能、同步配置、管理 Provider，也可以通过 Ops 面板执行项目级操作。

> 安装新的 Skill / MCP / Context，或更改 Provider、权限后，需要**重启对应的 AI 工具客户端**（Claude Code / Codex CLI / Gemini CLI / OpenCode）才能生效。如需保留对话上下文，以 resume / continue 方式重启即可。

完整的快速开始、命令参考、配置路径说明请参考 aic 文档站的「快速开始」与「快捷键与命令参考」页面。

## 3. Registry 内容

本仓库是 aic 的公共 Registry 与内容仓库，提供以下可被 `aic install` / `aic sync` 使用的模板：

### Skills

当前注册表（`skills/index.yaml`）包含以下技能，按分类组织：


| 分类          | 技能                             | 作用简介                                                        |
| ------------- | -------------------------------- | --------------------------------------------------------------- |
| `common`      | `challenge`                      | 以陌生者视角审查代码，按危险程度排序输出风险点                  |
| `common`      | `dev-plan`                       | 生成/增量更新`dev-plan.md`，按 Phase/Task 拆解开发计划          |
| `common`      | `git-commit`                     | 基于暂存变更与上下文生成规范中文 commit message 并提交          |
| `common`      | `glab-manage`                    | 按开发计划在 GitLab 创建 Issue 并回写编号                       |
| `common`      | `readme-doc`                     | 为项目生成格式化的 README.md                                    |
| `domain`      | `docker-deploy`                  | 生成 Dockerfile + docker-compose.yml + build.sh + .dockerignore |
| `domain`      | `k8s-deploy`                     | 生成全量 k8s.yaml + 增量 update.yaml                            |
| `meta`        | `aic-contexts-creator`           | 为 registry 创建、迁移和增量更新 context 包                     |
| `meta`        | `aic-mcp-creator`                | 为 registry 创建、审查和增量更新 MCP server 包                  |
| `meta`        | `aic-skill-creator`              | 编写、设计、改进 aic 内部`SKILL.md` 文件                        |
| `superpowers` | `brainstorming`                  | 在实现前探索用户意图、需求与设计                                |
| `superpowers` | `systematic-debugging`           | 遇到 bug / 测试失败 / 异常行为时的系统化排查流程                |
| `superpowers` | `test-driven-development`        | TDD 流程：先写测试再写实现                                      |
| `superpowers` | `verification-before-completion` | 声明工作完成前先运行验证命令并确认输出                          |
| `superpowers` | `writing-plans`                  | 多步任务的实现计划编写                                          |
| `superpowers` | `using-git-worktrees`            | 通过 git worktree 隔离工作区                                    |
| `superpowers` | `dispatching-parallel-agents`    | 并行调度多个 sub-agent 处理独立任务                             |
| `superpowers` | `executing-plans`                | 在独立 session 中按检查点执行实现计划                           |
| `superpowers` | `subagent-driven-development`    | 在当前 session 中用 sub-agent 执行实现计划                      |
| `superpowers` | `finishing-a-development-branch` | 实现完成后的分支集成决策                                        |
| `superpowers` | `requesting-code-review`         | 完成任务 / 合并前的代码审查请求                                 |
| `superpowers` | `receiving-code-review`          | 接收代码审查反馈时的处理流程                                    |
| `superpowers` | `writing-skills`                 | 创建、编辑、验证 skill                                          |
| `superpowers` | `using-superpowers`              | 会话开始时建立 skill 发现与使用机制                             |

完整索引与每个 skill 的触发语义见 `skills/index.yaml` 与各 skill 目录下的 `SKILL.md`。

### Contexts

项目级长期记忆模板，按开发阶段组织：

- `01-incubation-prototype` — 孵化期 / 原型阶段
- `02-iteration-evolution` — 迭代演进阶段
- `03-maintenance-stable` — 维护稳定阶段
- `04-refactor-evolution` — 重构演进阶段
- `project-coding-guideline` — 项目编码规范模板

### MCP Servers

可被 `aic mcp install` 安装的 MCP server 模板：

- `codegraph`
- `searxng-http`

### Providers

四个 AI 工具的 Provider 示例配置，用于 `aic` 的 Provider 多模型切换：

- `providers/claude/`
- `providers/codex/`
- `providers/gemini/`
- `providers/opencode/`

### 其他

- `permissions/` — 权限模板
- `gitignore/` — 本地忽略规则模板

## 4. 仓库结构

```text
.
├── skills/          # 公开 Skill 库（含 index.yaml）
├── contexts/        # Context 模板（按开发阶段）
├── mcp-servers/     # MCP server 模板
├── providers/       # Provider 示例配置（claude / codex / gemini / opencode）
├── permissions/     # 权限模板
├── gitignore/       # 本地忽略规则模板
├── docs/            # 仓库级文档
├── scripts/         # 索引生成等工具脚本
├── registry.yaml    # Registry 元数据
├── aic-release.yaml # aic 版本、MD5 与更新列表
├── VERSION          # Registry 自身版本
└── README.md
```

> **注意**：aic 核心二进制是闭源的，本仓库**不包含** aic 源码。仓库仅存放 Registry 内容（Skills / Contexts / MCP / Providers 等模板）与发布元数据。

## 5. Registry 与 aic 版本

- 根目录 `VERSION` 是 registry 自身版本，用于标识 registry 内容的发布状态。
- 根目录 `aic-release.yaml` 记录 aic 版本、二进制 MD5 和中文更新列表；`registry.yaml` 通过 `aic_release` 字段指向该文件。
- aic 拉取 registry 后会读取该文件，将自身版本与 `version` 精确比较；不一致时展示 `features` 并提示升级。

维护命令：

```bash
make set-version VERSION=v0.2.0
```

## 6. 贡献与反馈

- **问题反馈**：在 GitHub 或 Gitee 仓库提 Issue
  - GitHub Issues：https://github.com/KaiyuanEra/aic-registry/issues
  - Gitee Issues：https://gitee.com/KaiyuanEra/aic-registry/issues
- **邮箱**：kaiyuanera@zohomail.com
- **文档站**：完整文档请访问 aic 文档站（Cloudflare Pages 部署后回填链接）

## License

本仓库中的 Skills / Contexts / MCP server / Provider 模板等内容可公开使用。
