# GitLab CI 变量配置指南

## CI/CD Settings 中需要配置的变量

进入 GitLab 项目 → Settings → CI/CD → Variables，添加以下变量：

| 变量名 | 类型 | 说明 |
|--------|------|------|
| `CI_REGISTRY_USER` | Variable | 镜像仓库登录用户名 |
| `CI_REGISTRY_PASSWORD` | Variable（Masked） | 镜像仓库登录密码，勾选 Masked 防止日志泄露 |

## GitLab 内置变量速查

| 变量 | 示例值 | 说明 |
|------|--------|------|
| `CI_COMMIT_SHORT_SHA` | `a1b2c3d4` | 当前提交的短 SHA（8位） |
| `CI_COMMIT_REF_NAME` | `main` / `dev` | 当前分支名或 tag 名 |
| `CI_COMMIT_TAG` | `v1.0.0` | 当前 tag 名（仅 tag 触发时有值） |
| `CI_PROJECT_NAME` | `my-app` | 项目名称 |
| `CI_PIPELINE_ID` | `12345` | 流水线 ID |

## 动态 IMAGE_TAG 说明

```yaml
IMAGE_TAG: "${CI_COMMIT_REF_NAME}-${CI_COMMIT_SHORT_SHA}"
```

示例：`main-a1b2c3d4`、`dev-f5e6d7c8`

这样每次构建都有唯一 tag，便于追溯和回滚。

## 增量更新 .gitlab-ci.yml 的注意事项

1. **只改 VERSION 时**：定位到 `variables:` 块中的 `VERSION:` 行，只替换版本号值
2. **添加新 job 时**：在 `stages:` 列表末尾追加新 stage，在文件末尾追加完整 job 定义
3. **不要整体替换文件**：避免覆盖已有的自定义配置和注释
4. **更新时间戳**：每次修改后更新文件头部的"最后更新"字段

## Docker-in-Docker（DinD）说明

```yaml
image: {registry}/paas/docker:24
services:
  - {registry}/paas/docker:24
variables:
  DOCKER_BUILDKIT: "0"   # DinD 环境下关闭 BuildKit，避免兼容性问题
```

DinD 模式下 `docker` 命令通过 TCP 连接到 service 容器，需要关闭 BuildKit。
