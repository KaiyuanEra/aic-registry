---
name: ims-package-docker
version: 1.0.1
description: >
  生成 IMS 边缘下发应用安装包（Docker Compose 模式），包含打包脚本和 Makefile 集成。
  Use when 帮我打包应用、生成 IMS 安装包、make packages 之前需要做什么、generate edge package、
  用户提到 IMS / 边缘下发 / 安装包 / 打包，且部署模式为 Docker Compose 或未指定模式。
  Do NOT use for docker build / CI 构建镜像、只讨论部署架构不需要生成文件、
  systemd 二进制部署模式（使用 ims-package-systemd）。
tags: [ims, packaging, docker, edge-deploy]
env-required: false
---

# ims-package-docker

引导生成符合 IMS 规范的 Docker Compose 模式安装包，核心产出是 `scripts/create_package.sh`。

**权威来源：** 脚本实现为准，文档冲突以脚本逻辑为准。

---

## 执行前检查

```
① 检测 APP_NAME
   优先从 Makefile APP_NAME 变量读取
   次之从 go.mod module 名推断（取最后一段）
   均无 → 询问用户

② 检测 HEALTH_PORT
   从现有 docker-edge-compose.yml ports 字段读取
   无 → 默认 50099，告知用户

③ 检测必需文件（缺失则提示用户先创建）
   docker/docker-edge-compose.yml    ← 必须存在
   docker/docker-rollback-compose.yml ← 必须存在
   docker/dirs.log                   ← 必须存在

④ 检测 scripts/create_package.sh 是否已存在
   存在 → 询问是否覆盖
```

---

## 生成流程

### Step 1：生成 scripts/create_package.sh

读取 `assets/create_package.sh.template`，替换以下占位符后写入 `scripts/create_package.sh`：

| 占位符 | 替换值 |
|--------|--------|
| `{{APP_NAME}}` | 检测到的应用名（小写，如 raccoon） |
| `{{HEALTH_PORT}}` | 健康检查端口（默认 50099） |
| `{{APP_DESCRIPTION}}` | 应用描述（可从 README 提取，或留空让用户填写） |

替换后执行：
```bash
chmod +x scripts/create_package.sh
```

### Step 2：Makefile 集成

检测 Makefile 是否存在：
- **不存在** → 新建，写入以下内容
- **存在** → 检查是否已有 `packages` target，无则追加

```makefile
# ============================================================
# IMS 边缘下发安装包
# ============================================================
APP_NAME  ?= {{APP_NAME}}
VERSION   ?= dev
ENV       ?= prod
OUTPUT_DIR = dist/packages

.PHONY: package packages
package: packages
packages:
	@echo "Creating Docker Compose package..."
	@mkdir -p $(OUTPUT_DIR)
	VERSION=$(VERSION) ENV=$(ENV) OUTPUT_DIR=$(OUTPUT_DIR) \
	  APP_NAME=$(APP_NAME) ./scripts/create_package.sh
	@echo "Package created: $(OUTPUT_DIR)/$(APP_NAME)-$(VERSION).tar.gz"

help:
	@echo "IMS Package:"
	@echo "  make packages                        - 默认版本打包"
	@echo "  make packages VERSION=1.0.1          - 指定版本"
	@echo "  make packages VERSION=1.0.1 ENV=prod - 指定版本和环境"
```

### Step 3：交付说明

生成完成后告知用户：

```
已生成：
  scripts/create_package.sh   ← 打包脚本（已 chmod +x）
  Makefile                    ← 已追加 packages target

使用方式：
  make packages VERSION=1.0.1
  make packages VERSION=1.0.1 ENV=prod

打包产出：
  dist/packages/{{APP_NAME}}-1.0.1.tar.gz   ← 上传到 IMS Agent
  dist/packages/1.0.1/                       ← 未压缩内容（便于排查）

安装包内容（IMS Agent 解压后执行 install.sh）：
  app.yaml
  scripts/install.sh / uninstall.sh / rollback.sh / start.sh / stop.sh
  scripts/docker-edge-compose.yml
  scripts/docker-rollback-compose.yml
  config/dirs.log
```

---

## 安装包结构（参考）

```
{{APP_NAME}}-{{VERSION}}/
├── app.yaml
├── scripts/
│   ├── install.sh               # 升级脚本（含首次部署分支）
│   ├── uninstall.sh
│   ├── rollback.sh
│   ├── start.sh
│   ├── stop.sh
│   ├── docker-edge-compose.yml
│   └── docker-rollback-compose.yml
└── config/
    └── dirs.log
```

---

## 规范参考

- app.yaml 格式：[references/app-yaml-spec.md](references/app-yaml-spec.md)
- 健康检查规范：[references/health-check-spec.md](references/health-check-spec.md)
- UTF-8 编码校验：[references/encoding-validate.md](references/encoding-validate.md)
- Agent 环境变量：[references/ims-agent-envvars.md](references/ims-agent-envvars.md)
