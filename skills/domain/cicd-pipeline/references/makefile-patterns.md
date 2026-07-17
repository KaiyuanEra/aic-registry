# Makefile 常用模式参考

## K8s 部署命令（追加示例）

```makefile
# ---- 追加于 {timestamp} ----
.PHONY: deploy-k8s
deploy-k8s:                    ## 部署到 K8s（全量）
	@kubectl apply -f docker/$(VERSION)/k8s.yaml
	@echo "全量部署完成，版本: $(VERSION)"

.PHONY: update-k8s
update-k8s:                    ## 滚动更新 K8s 镜像（增量）
	@kubectl apply -f docker/$(VERSION)/update.yaml
	@echo "镜像更新完成，版本: $(VERSION)"

.PHONY: k8s-status
k8s-status:                    ## 查看 K8s 部署状态
	@kubectl get pods -n {namespace} -l app={app-name}
	@kubectl get svc -n {namespace} -l app={app-name}
```

## 测试命令模式

```makefile
.PHONY: test
test:                          ## 运行单元测试
	@go test ./... -v

.PHONY: test-cover
test-cover:                    ## 运行测试并生成覆盖率报告
	@go test ./... -coverprofile=coverage.out
	@go tool cover -html=coverage.out -o coverage.html
	@echo "覆盖率报告：coverage.html"
```

## 代码质量命令模式

```makefile
.PHONY: lint
lint:                          ## 运行代码检查
	@golangci-lint run

.PHONY: fmt
fmt:                           ## 格式化代码
	@gofmt -w .
	@echo "代码格式化完成"
```

## help 命令工作原理

```makefile
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
```

- `grep` 匹配所有包含 `## ` 注释的 target 行
- `awk` 格式化输出：target 名称（青色）+ 说明文字
- 要让 target 出现在 help 中，格式必须为：`target:  ## 说明`
