---
name: cicd-pipeline
version: 1.1.1
description: 生成和维护 .gitlab-ci.yml（GitLab CI 流水线）和 Makefile（本地构建命令，仅首次新建，不追加）。Use when 帮我生成 CI/CD 配置、更新 .gitlab-ci.yml、生成 Makefile、配置 GitLab 流水线、生成构建脚本，or when user mentions CI / CD / pipeline / Makefile。Do NOT use for Docker 文件生成（→ docker-deploy）、K8s yaml 生成（→ k8s-deploy）、只讨论 CI 概念不需要生成文件。
env-required: false
---

# cicd-pipeline

生成和维护两个文件：`.gitlab-ci.yml`（GitLab CI 流水线）和 `Makefile`（本地构建命令）。

---

## Makefile 生成规范

参考 `assets/Makefile.template`。

**生成规则：**

```
Makefile 不存在 → 新建完整 Makefile（含 help 目标和变量定义）
Makefile 已存在 → 不修改，提示用户手动编辑
```

### 规范要求

- 所有自定义 target 必须声明 `.PHONY`
- 每个 target 后必须有 `## 注释`（供 help 命令解析）
- 注释格式：`target:  ## 说明文字（中文）`
- 相关命令分组，组间用 `# ====` 分隔注释
- 变量定义使用 `?=`（允许命令行覆盖：`make build VERSION=1.1.0`）
- 输出信息用 `@echo`，命令前加 `@` 抑制回显
- 不在 Makefile 中硬编码密码或 token

### 变量定义（与 docker/env.sh 保持同步）

```makefile
PROGRAM     ?= {registry}/{namespace}/{image-name}
VERSION     ?= {x.y.z}
ENV         ?= prod
PLATFORM    ?= linux/amd64
```

---

## .gitlab-ci.yml 生成规范

参考 `assets/gitlab-ci.yml.template`。

### 维护规则

**新建时：** 生成完整结构（含注释、stages、variables、build job）

**已有文件时（增量更新）：**

| 用户意图 | 操作 |
|----------|------|
| "更新版本号" | 只修改 `variables.VERSION` 字段，不修改其他内容 |
| "添加新 stage/job" | 在 stages 末尾追加 stage 名称，在文件末尾追加完整 job 定义 |
| "修改构建参数" | 定位到具体字段修改，明确告知修改了哪一行，提供修改前后对比 |

**任何情况下：**
- 不删除已有 job
- 不修改已有注释
- 修改后在文件头部更新"最后更新"时间戳

### 关键变量说明

```yaml
# GitLab 内置变量
# CI_COMMIT_SHORT_SHA   : 当前提交的短 SHA（8位）
# CI_COMMIT_REF_NAME    : 当前分支名或 tag 名
# CI_REGISTRY_USER      : GitLab 仓库登录用户（在 CI/CD Settings 中配置）
# CI_REGISTRY_PASSWORD  : GitLab 仓库登录密码（在 CI/CD Settings 中配置）

# 自定义变量
# VERSION               : 应用版本号，需手动与 docker/env.sh 保持同步
# REGISTRY              : 私有镜像仓库地址
# CI_REGISTRY_IMAGE     : 完整镜像路径（含仓库地址和命名空间）
# IMAGE_TAG             : 动态 tag，格式为 {分支名}-{短SHA}
```

详见 `references/gitlab-ci-guide.md`。

---

## 执行后提示

```
Makefile 已生成，运行 make help 查看所有命令
CI 配置已生成，请确认 .gitlab-ci.yml 中的 VERSION 与 docker/env.sh 一致
```
