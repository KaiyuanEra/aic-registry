---
name: ims-package-systemd
version: 1.0.1
description: >
  生成 IMS 边缘下发应用安装包（二进制 + systemd 模式），包含打包脚本、systemd unit 模板和 Makefile 集成。
  Use when 帮我打包应用、生成 IMS 安装包、systemd 部署打包、generate edge package，
  且部署模式为 systemd / 二进制 / 非 Docker，或用户明确提到 systemd。
  Do NOT use for Docker Compose 部署模式（使用 ims-package-docker）、
  只讨论部署架构不需要生成文件、docker build / CI 构建镜像。
tags: [ims, packaging, systemd, edge-deploy, binary]
env-required: false
---

# ims-package-systemd

引导生成符合 IMS 规范的 systemd 二进制模式安装包，核心产出是 `scripts/create_package_systemd.sh`。

---

## 执行前检查

```
① 检测 APP_NAME
   优先从 Makefile APP_NAME 变量读取
   次之从 go.mod module 名推断（取最后一段）
   均无 → 询问用户

② 检测 HEALTH_PORT（默认 50099）

③ 检测 Makefile 中的 build-linux 目标
   存在 → 提示执行 make build-linux，找到产出 binary 路径
   不存在 → 追加 build-linux 目标（见 Step 0）

④ 检测 binary 是否存在
   优先 bin/{{APP_NAME}}-linux-amd64
   次之 bin/{{APP_NAME}}（提示可能架构不匹配）
   均无 → 提示执行 make build-linux 后重试

⑤ 检测 config/{{APP_NAME}}.service 是否存在
   不存在 → 从 assets/service.unit.template 生成（见 Step 0b）
```

---

## Step 0：编译引导

### 0a：Makefile build-linux 目标

检测 Makefile 是否有 `build-linux` 或 `GOOS=linux GOARCH=amd64`：
- **无** → 追加以下内容（替换 `{{APP_NAME}}` 和 `{{MAIN_PACKAGE}}`）：

```makefile
# ============================================================
# 编译
# ============================================================
BINARY_NAME  = {{APP_NAME}}
BUILD_DIR    = bin
MAIN_PACKAGE = ./cmd/{{MAIN_PACKAGE}}

.PHONY: build build-linux
build:
	go build -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PACKAGE)

build-linux:
	GOOS=linux GOARCH=amd64 \
	  go build -ldflags="-X main.Version=$(VERSION)" \
	  -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 \
	  $(MAIN_PACKAGE)
```

`{{MAIN_PACKAGE}}` 从 `cmd/` 目录下的子目录名推断，无法推断则询问用户。

### 0b：生成 systemd unit 模板

读取 `assets/service.unit.template`，替换 `{{APP_NAME}}` 后写入 `config/{{APP_NAME}}.service`。

其余占位符（`{{SERVICE_USER}}`、`{{WORKING_DIRECTORY}}` 等）保留，由用户手动填写。
常见参考值：
- `BINARY_PATH` → `/opt/apps/{{APP_NAME}}/current/bin/{{APP_NAME}}`
- `SERVICE_USER` → `root` 或专用服务账号
- `WORKING_DIRECTORY` → `/opt/apps/{{APP_NAME}}/current`

---

## 生成流程

### Step 1：生成 scripts/create_package_systemd.sh

读取 `assets/create_package_systemd.sh.template`，替换占位符后写入：

| 占位符 | 替换值 |
|--------|--------|
| `{{APP_NAME}}` | 应用名 |
| `{{HEALTH_PORT}}` | 健康检查端口（默认 50099） |
| `{{APP_DESCRIPTION}}` | 应用描述 |

```bash
chmod +x scripts/create_package_systemd.sh
```

### Step 2：Makefile 集成

检测是否已有 `packages` target，无则追加：

```makefile
# ============================================================
# IMS 边缘下发安装包（systemd 模式）
# ============================================================
APP_NAME   ?= {{APP_NAME}}
VERSION    ?= dev
ENV        ?= prod
OUTPUT_DIR  = dist/packages

.PHONY: package packages
package: packages
packages: build-linux
	@echo "Creating systemd package..."
	@mkdir -p $(OUTPUT_DIR)
	VERSION=$(VERSION) ENV=$(ENV) OUTPUT_DIR=$(OUTPUT_DIR) \
	  APP_NAME=$(APP_NAME) ./scripts/create_package_systemd.sh
	@echo "Package created: $(OUTPUT_DIR)/$(APP_NAME)-$(VERSION).tar.gz"
```

### Step 3：交付说明

```
已生成：
  config/{{APP_NAME}}.service         ← systemd unit 模板（需填写占位符）
  scripts/create_package_systemd.sh   ← 打包脚本（已 chmod +x）
  Makefile                            ← 已追加 build-linux + packages target

下一步：
  1. 编辑 config/{{APP_NAME}}.service，填写 {{SERVICE_USER}} 等占位符
  2. make build-linux
  3. make packages VERSION=1.0.1

安装包内容（IMS Agent 解压后执行 install.sh）：
  app.yaml
  scripts/install.sh / uninstall.sh / rollback.sh / start.sh / stop.sh
  bin/{{APP_NAME}}
  config/{{APP_NAME}}.service
```

---

## 安装包结构（参考）

```
{{APP_NAME}}-{{VERSION}}/
├── app.yaml
├── scripts/
│   ├── install.sh    # systemctl stop + 软链接切换 + systemctl start
│   ├── uninstall.sh
│   ├── rollback.sh   # 读取 previous 软链接 + 切换 current
│   ├── start.sh      # systemctl start
│   └── stop.sh       # systemctl stop
├── bin/
│   └── {{APP_NAME}}  # Linux amd64 binary
└── config/
    └── {{APP_NAME}}.service
```

---

## 规范参考

- app.yaml 格式：[references/app-yaml-spec.md](references/app-yaml-spec.md)
- 健康检查规范：[references/health-check-spec.md](references/health-check-spec.md)
- UTF-8 编码校验：[references/encoding-validate.md](references/encoding-validate.md)
- Agent 环境变量：[references/ims-agent-envvars.md](references/ims-agent-envvars.md)
- 软链接管理：[references/symlink-strategy.md](references/symlink-strategy.md)
