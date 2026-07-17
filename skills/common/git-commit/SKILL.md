---
name: git-commit
version: 1.0.4
description: >
  根据 git 变更和开发上下文生成规范的中文 commit message 并执行提交。
  Use when committing code, writing a commit message, or completing a development task,
  or when user mentions 提交代码、帮我 commit、写个 commit、commit 一下、
  代码写完了、task 完成了、帮我提交、git commit。
  Do NOT use for git push、merge、rebase、cherry-pick 等其他 git 操作，
  只查看 git 状态，或拉取远端代码。
tags: [git, dev-workflow, commit]
env-required: false
---

# git-commit

根据暂存区变更（`git diff --staged`）和开发上下文，生成规范的中文 commit message 并确认提交。

**设计原则：** 能关联就关联，不强制；服务中文开发者阅读习惯。

---

## 执行前检查

```
暂存区为空？
  是 → 提示：请先 git add 目标文件，再执行提交
  否 → 继续
```

---

## 上下文感知链

按序检测，自动推断关联 Task 和 Issue：

```
① 检测 docs/dev-plan.md
   存在 → 读取进行中 Task 列表，提取"涉及文件"字段

② 交叉匹配变更文件路径
   变更文件 ∩ Task 涉及文件 → 推断关联 Task 和 Issue 编号

③ 检测 git branch 名称
   含 issue-{n} 或 #{n} → 提取 Issue 编号

④ 以上均无 → 独立模式，纯根据 diff 内容生成 commit

感知结果展示给用户确认，不静默关联
```

---

## Commit Message 规范

**格式：**
```
{type}({scope}): {中文描述}

{正文（可选）}

{footer（可选）}
```

**type 枚举：**

| type | 含义 | 示例场景 |
|------|------|----------|
| `feat` | 新功能 | 实现新命令、新模块 |
| `fix` | 修复 bug | 修复链接创建失败 |
| `refactor` | 重构 | 不改行为，优化结构 |
| `docs` | 文档变更 | 更新 dev-plan.md、README |
| `chore` | 工程配置 | 修改 Makefile、依赖更新 |
| `test` | 测试相关 | 添加单测、修复测试 |
| `perf` | 性能优化 | 减少不必要 API 调用 |

**标题行规范：**
- 中文描述，动词开头，20–50 字
- scope 用模块名，不用文件名
- 不加句号结尾

**footer 关联 Issue：**
```
进行中（不关闭）：Refs #42
完成并关闭：     Closes #42   ← 由步骤 5 Task 完成状态决定，不手动判断
多个：           Refs #42, #43 / Closes #44
新项目无 Issue：  footer 留空
```

type/scope 详细选择指南见 [references/type-scope-guide.md](references/type-scope-guide.md)，
各场景示例见 [references/examples.md](references/examples.md)。

---

## 工作流程

1. **读取变更** — `git diff --staged`，分析变更文件和改动性质
2. **感知上下文** — 运行 `scripts/context-detect.sh` 检测 dev-plan 和 branch
3. **生成草稿** — 输出 commit message 并展示确认界面：

```
┌─ 建议的 commit message ──────────────────────────────┐
│                                                       │
│  feat(parser): 实现 SKILL.md frontmatter 解析          │
│                                                       │
│  新增 ParseSkill() 函数，解析 YAML 头提取              │
│  name/version/description/env-required 字段，          │
│  version 格式非 semver 时返回明确错误。                │
│                                                       │
│  Closes #42                                           │
│                                                       │
│  变更文件：internal/skill/parser.go (+120 -0)          │
│           internal/skill/model.go  (+45 -3)           │
└───────────────────────────────────────────────────────┘

[y] 确认提交  [e] 编辑后提交  [r] 重新生成  [n] 取消
```

4. **执行提交** — 用户确认后执行 `git commit`
5. **同步 dev-plan.md 并关闭 Issue** — 提交成功后，若关联了 Task，询问该 Task 是否已完成：

```
关联 Task 已完成？
  是 → 运行 scripts/close-issue.sh <issue_number>
       脚本负责：① 调用 GitLab/GitHub API 关闭 Issue
                ② 更新 dev-plan.md 中对应 Task 状态为"已完成"
       commit message footer 使用 Closes #n
       将 dev-plan.md 变更追加到本次 commit（git commit --amend）
       或作为独立 docs commit（用户可选）
  否 → 状态保持"进行中"，footer 使用 Refs #n，不修改 dev-plan.md

dev-plan.md 不存在 → 跳过此步骤
未关联任何 Task   → 跳过此步骤
```

> 脚本自动从 `git remote origin` 推断平台（GitLab/GitHub）和项目路径。
> Token 读取优先级：当前项目 `.aic/.aic-env` → `~/.aic/aic-env` → shell 环境变量。
> 未找到 token 时**不报错、不阻断提交**，仅跳过关闭 Issue 步骤并提示配置方式。
> 推荐通过安装 `glab-manage` skill 统一管理 `GITLAB_TOKEN`（`aic env add GITLAB_TOKEN`）。
> 可先用 `--dry-run` 预览不实际调用 API：
> `bash scripts/close-issue.sh 42 --dry-run`

6. **提示 push** — 提交完成后询问是否 `git push`（不自动执行）

---

## 新项目 vs 老项目

```
新项目简化模式（满足任一）：
  ① dev-plan.md 中 Task 的 Issue 字段全部为"#（待创建）"
  ② 用户明确说"还没建 issue"

  → footer 留空，正文可选，重点保证标题格式正确

老项目标准模式：
  → 尽量关联 Issue，复杂变更补充正文，严格 type/scope
```

---

## 常见边缘情况

| 情况 | 处理方式 |
|------|----------|
| 变更横跨多个 Task | 拆分为多次 commit，每次只提交相关文件 |
| 无法判断 type | 输出变更分析，列出候选 type 让用户选择 |
| 关联到多个 Issue | footer 列出所有：`Refs #42, #43` |
| dev-plan.md 不存在 | 降级为独立模式，不影响 commit 生成 |
| 暂存了非预期文件 | 展示 staged 文件列表，提示确认后再继续 |
