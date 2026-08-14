---
name: docker-deploy
version: 1.1.1
description: 生成 Docker 本地部署所需的全套文件（Dockerfile、docker-compose.yml、build.sh、.dockerignore），输出到 docker/ 目录。Use when 帮我生成 Docker 部署文件、生成 docker-compose、创建 build.sh 构建脚本、初始化 docker 目录，or when user mentions Dockerfile / docker-compose / 容器部署 / build.sh。Do NOT use for K8s 部署配置生成（→ k8s-deploy）、CI/CD 流水线配置（→ cicd-pipeline）、只讨论 Docker 概念不需要生成文件。
env-required: false
---

# docker-deploy

根据用户描述的项目信息，生成 Docker 本地部署所需的全套文件。

**不负责：** Dockerfile 内部的编译逻辑。只负责生成文件骨架、填充部署相关配置。

---

## 输出目录结构

```
项目根目录/
├── docker/
│   ├── .dockerignore           # 全局 dockerignore
│   ├── Dockerfile              # 多阶段构建骨架
│   ├── env.sh                  # 构建变量（PROGRAM / VERSION / ENV / GOPROXY / APT_MIRROR）
│   ├── build.sh                # 构建入口脚本（读取 env.sh）
│   └── docker-compose.yml      # 本地运行配置
│
└── Makefile                    # 构建命令入口（由 cicd-pipeline 维护）
```

---

## 文件生成规范

### `docker/env.sh`

```bash
#!/bin/bash
# 镜像构建配置
# 生成时间：{timestamp}

PROGRAM={registry}/{team}/{app-name}  # 完整镜像名，含仓库地址
VERSION={x.y.z}                        # 语义化版本号
ENV=prod                               # 运行环境：prod / dev / staging
GOPROXY=https://goproxy.cn,https://goproxy.io,direct  # Go 模块代理（国内构建必须）
APT_MIRROR=mirrors.aliyun.com          # apt 国内镜像源（可选：mirrors.tuna.tsinghua.edu.cn）
```

**要求：**
- `PROGRAM` 格式严格为 `{registry}/{namespace}/{image-name}`，三段式
- 不在此文件中放敏感信息（密码、token 等）

### `docker/Dockerfile`

**要求：**
- 多阶段构建（builder + runtime），builder 阶段负责编译，runtime 阶段只复制产物
- 必须声明 `ARG GOPROXY` 并紧跟 `ENV GOPROXY=$GOPROXY`，位置在 `go mod download` 之前：

```dockerfile
ARG GOPROXY=https://goproxy.cn,https://goproxy.io,direct
ENV GOPROXY=$GOPROXY

RUN go mod download
```

- `go mod download` 或 `go mod tidy` 前必须有上述两行，否则国内容器构建会因无法访问 golang.org 而失败
- `ARG VERSION` 和 `ARG ENV` 同样需要声明，供运行时标识使用
- runtime 阶段使用最小基础镜像（`alpine` 或 `distroless`），不包含 Go 工具链

**国内包管理源配置（凡有 `apt-get` / `apk` / `pip` 等安装命令，必须在安装前切换国内源）：**

镜像源通过 `ARG APT_MIRROR` 传入，默认阿里源，构建时可覆盖：

```dockerfile
ARG APT_MIRROR=mirrors.aliyun.com
```

| 基础镜像 | 包管理器 | 国内源配置方式 |
|----------|----------|----------------|
| `debian` / `ubuntu` | `apt-get` | 用 `ARG APT_MIRROR` 替换源地址，**必须用 HTTP 不用 HTTPS**（ca-certificates 未装时 HTTPS 握手失败） |
| `alpine` | `apk` | `sed` 替换 `dl-cdn.alpinelinux.org` 为 `$APT_MIRROR` |
| `python` | `pip` | `-i http://$APT_MIRROR/pypi/simple --trusted-host $APT_MIRROR` |

debian/ubuntu 示例：

```dockerfile
ARG APT_MIRROR=mirrors.aliyun.com
# 用 HTTP 而非 HTTPS：ca-certificates 未安装时 HTTPS 握手会失败
RUN sed -i "s|http://deb.debian.org/debian|http://${APT_MIRROR}/debian|g" /etc/apt/sources.list.d/debian.sources \
    && sed -i "s|http://security.debian.org/debian-security|http://${APT_MIRROR}/debian-security|g" /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*
```

alpine 示例：

```dockerfile
ARG APT_MIRROR=mirrors.aliyun.com
RUN sed -i "s/dl-cdn.alpinelinux.org/${APT_MIRROR}/g" /etc/apk/repositories \
    && apk add --no-cache tzdata ca-certificates
```

**规则：** 检测到 Dockerfile 中有任何包安装命令时，自动在该 `RUN` 块前声明 `ARG APT_MIRROR` 并插入对应的源替换命令，并在注释中注明"国内镜像源，HTTP 避免证书问题"。

### `docker/build.sh`

参考 `assets/build.sh.template`。

**要求：**
- `set -e` 必须保留
- 参数解析保持 `while/case` 结构
- 所有用户可见提示信息使用中文

### `docker/docker-compose.yml`

参考 `assets/docker-compose.yml.template`。

**要求：**
- 不写 `version:` 字段（新版 Docker Compose 已废弃，写了会有 WARN）
- `image` 字段必须使用 `${VARIABLE:-default}` 格式
- 必须包含 `healthcheck` 配置
- 日志配置默认 `max-size: 100m / max-file: 5`
- 时区：只挂载 `/etc/localtime:ro`，同时设置环境变量 `TZ=Asia/Shanghai`；**不挂载 `/etc/timezone`**（部分系统该文件不存在或类型不符，挂载会报 OCI runtime 错误）
- 敏感变量不写入此文件，引用外部 `.env` 文件

### `docker/.dockerignore`

参考 `assets/.dockerignore.template`。

---

## 文件操作安全规则

| 文件 | 策略 |
|------|------|
| `docker/env.sh` | 已存在时只修改用户明确要求的字段，其他保留 |
| `docker/docker-compose.yml` | 整体生成（可覆盖） |
| `docker/.dockerignore` | 整体生成（可覆盖） |
| `docker/build.sh` | 整体生成（可覆盖） |
| `docker/Dockerfile` | 已存在时询问用户是否覆盖 |

任何写操作前，展示将要进行的操作，等待用户确认后再执行。

---

## 敏感信息处理

- `docker-compose.yml` → 引用外部 `.env` 文件，或注释说明通过环境变量注入
- 发现用户提供的信息中包含明显的密码或 token 时，提示用户不要将此信息放入代码仓库，在生成文件中用占位符代替

---

## 执行后提示

```
docker/ 目录已生成，构建命令：./docker/build.sh
如需 K8s 部署配置，继续执行 k8s-deploy skill
```
