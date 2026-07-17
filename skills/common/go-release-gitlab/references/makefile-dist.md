# Makefile dist 目标参考

Go 项目 `dist` 目标的标准写法，生成 4 平台交叉编译产物 + checksums。

## 最小可用模板

```makefile
APP     ?= myapp
VERSION ?= dev
DIST    := dist

PLATFORMS := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64

.PHONY: dist clean

dist: clean
	@mkdir -p $(DIST)
	@for platform in $(PLATFORMS); do \
	  os=$${platform%/*}; arch=$${platform#*/}; \
	  out=$(DIST)/$(APP)_$(VERSION)_$${os}_$${arch}; \
	  echo "building $${os}/$${arch}..."; \
	  GOOS=$$os GOARCH=$$arch go build -ldflags="-s -w -X main.version=$(VERSION)" \
	    -o $$out ./cmd/$(APP)/; \
	  tar -czf $${out}.tar.gz -C $(DIST) $(APP)_$(VERSION)_$${os}_$${arch}; \
	  rm $$out; \
	done
	@cd $(DIST) && shasum -a 256 *.tar.gz > checksums.txt
	@echo "dist done: $(DIST)/"

clean:
	rm -rf $(DIST)
```

## 说明

- `APP` — 二进制名，与 `go-release-gitlab` 脚本中 `APP_NAME` 保持一致
- `VERSION` — 由 `make dist VERSION=v1.0.0` 传入，不要硬编码
- `ldflags -X main.version` — 可选，将版本号编译进二进制
- `checksums.txt` — 用 `shasum -a 256`（macOS/Linux 通用）

## 加入 release 目标和 help

将 `release` 命令也放进 Makefile，并配上 `help` 目标，方便团队成员查阅：

```makefile
APP     ?= myapp
VERSION ?= dev
DIST    := dist

PLATFORMS := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64

.PHONY: dist clean release help

## dist: 交叉编译并打包到 dist/（需传入 VERSION=vX.Y.Z）
dist: clean
	@mkdir -p $(DIST)
	@for platform in $(PLATFORMS); do \
	  os=$${platform%/*}; arch=$${platform#*/}; \
	  out=$(DIST)/$(APP)_$(VERSION)_$${os}_$${arch}; \
	  echo "building $${os}/$${arch}..."; \
	  GOOS=$$os GOARCH=$$arch go build -ldflags="-s -w -X main.version=$(VERSION)" \
	    -o $$out ./cmd/$(APP)/; \
	  tar -czf $${out}.tar.gz -C $(DIST) $(APP)_$(VERSION)_$${os}_$${arch}; \
	  rm $$out; \
	done
	@cd $(DIST) && shasum -a 256 *.tar.gz > checksums.txt
	@echo "dist done: $(DIST)/"

## release: 打包并发布到 GitLab Release（需设置 GITLAB_URL / GITLAB_PROJECT_ID / GITLAB_TOKEN）
release: dist
	PUSH_TAG=true sh scripts/release_gitlab.sh $(VERSION)

## clean: 删除 dist/ 目录
clean:
	rm -rf $(DIST)

## help: 显示可用目标
help:
	@grep -E '^## ' Makefile | sed 's/^## //'
```

`help` 目标通过扫描 `## target: 说明` 注释自动生成帮助文本，执行效果：

```
$ make help
dist: 交叉编译并打包到 dist/（需传入 VERSION=vX.Y.Z）
release: 打包并发布到 GitLab Release（需设置 GITLAB_URL / GITLAB_PROJECT_ID / GITLAB_TOKEN）
clean: 删除 dist/ 目录
help: 显示可用目标
```

## 验证

```bash
# dry-run，确认目标存在且参数正确
make -n dist VERSION=v0.0.0

# 查看帮助
make help
```
