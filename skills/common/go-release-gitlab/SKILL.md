---
name: go-release-gitlab
version: 2.1.1
description: >
  为 Go 项目执行本地一键交叉编译打包并发布到 GitLab Release。
  Use when releasing a Go project to GitLab, publishing a new version,
  or when user mentions 发布脚本、gitlab release、打包发布、发布新版本、
  go 项目发布、一键发布、版本发布、release 自动化、发布到 gitlab。
  Do NOT use for 创建 GitLab Issue 或 Milestone（使用 glab-manage skill）、
  git commit 操作（使用 git-commit skill），或只打包不发布的场景。
tags: [gitlab, release, go, dev-workflow]
env-required: true
env-vars:
  - name: GITLAB_URL
    description: GitLab 实例地址，如 https://git.ifogging.cn
    required: true
    target: skill
  - name: GITLAB_TOKEN
    description: Personal Access Token，需要 api scope（packages + releases 写权限）
    required: true
    target: skill
  - name: GITLAB_PROJECT_ID
    description: 项目数字 ID（GitLab 项目页 → 管理 → 常规 → 项目 ID）
    required: true
    target: skill
---

# go-release-gitlab

在目标项目根目录执行发布流程，**不向项目写入任何文件**（脚本内嵌于 skill，不落盘到项目仓库）：

1. `make clean dist VERSION=vX.Y.Z` 交叉编译打包到 `dist/`
2. 创建/复用 git tag（已存在则复用，不报错）
3. 上传 `dist/*.tar.gz` 和 `checksums.txt` 到 GitLab Generic Packages
4. 创建/更新 GitLab Release 并挂载 asset links

---

## 前置条件检查

执行前先确认：

```
① Makefile 存在且有 dist 目标
   验证：make -n dist VERSION=v0.0.0（dry-run，不实际执行）

② dist/ 产物命名约定（脚本依赖此格式）：
   dist/<app>_<version>_linux_amd64.tar.gz
   dist/<app>_<version>_linux_arm64.tar.gz
   dist/<app>_<version>_darwin_amd64.tar.gz
   dist/<app>_<version>_darwin_arm64.tar.gz
   dist/checksums.txt

③ git worktree 必须干净（无未提交变更）
```

Makefile `dist` 目标参考模板见 [references/makefile-dist.md](references/makefile-dist.md)。

---

## 执行步骤

1. **确认版本号** — 询问用户目标版本（如 `v1.2.0`），格式必须为 `vX.Y.Z`
2. **dry-run 验证** — 在项目根目录执行 `make -n dist VERSION=<version>`，确认 Makefile 配置正确
3. **执行发布** — 从项目根目录运行内嵌脚本：



> `scripts/release_gitlab.sh` 路径相对于本 skill 目录（如 claude cli 的  `.claude/skills/go-release-gitlab/scripts/release_gitlab.sh`），
> 执行时 **当前工作目录必须是目标项目根目录**。

4. **确认结果** — 输出 GitLab Release 页面链接：
   `<GITLAB_URL>/<project-path>/-/releases/<version>`

---

## 可选参数

| 环境变量 | 默认值 | 说明 |
|----------|--------|------|
| `PUSH_TAG` | `false` | 设为 `true` 时同时推送 tag 到 origin |
| `APP_NAME` | 从 `go.mod` 自动推断 | 覆盖应用名（影响产物文件名和 package 名） |
| `GITLAB_PROJECT_PATH` | 从 git remote 自动解析 | 覆盖 package URL 中的项目路径 |

---

## 常见边缘情况

| 情况 | 处理方式 |
|------|----------|
| Makefile 无 dist 目标 | 提示用户先配置，给出 [references/makefile-dist.md](references/makefile-dist.md) 参考 |
| git worktree 不干净 | 脚本直接报错退出，提示先 commit 或 stash |
| tag 已存在 | 复用已有 tag，不报错，继续上传和创建 Release |
| go.mod 不存在 | APP_NAME 降级为目录名，展示给用户确认后再继续 |
| git remote 无法解析 | 提示用户手动传入 `GITLAB_PROJECT_PATH=<path>` |
| dist/ 产物命名不符合约定 | 脚本跳过不存在的文件，asset links 会缺失，提示检查 Makefile |
| GITLAB_TOKEN 权限不足 | 明确说明需要 api scope，给出 Token 创建路径 |
| Release 已存在 | 自动改用 PUT 更新，不重复创建 |
