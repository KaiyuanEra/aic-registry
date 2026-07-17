---
name: app-yaml-spec
description: IMS app.yaml 格式规范
type: reference
---

# app.yaml 格式规范

IMS Agent 解压安装包后读取 `app.yaml` 获取应用元数据。

## 完整格式

```yaml
# 应用基本信息
name: {{APP_NAME}}               # 来自 $APP_NAME 环境变量，不硬编码
version: "{{VERSION}}"           # 来自 $VERSION 环境变量，打包时由 sed 替换 __VERSION__
description: {{描述文字}}

# 监听端口列表（Agent 用于端口冲突检测）
ports:
  - {{HEALTH_PORT}}              # 健康检查端口，默认 50099

# 健康检查配置
health_check:
  type: http
  urls:
    - http://127.0.0.1:{{HEALTH_PORT}}/health
  strategy: any
  timeout: 3000
```

## 字段说明

| 字段 | 必需 | 说明 |
|------|------|------|
| `name` | 是 | 应用名，与容器/服务名前缀一致 |
| `version` | 是 | 语义化版本，打包时由脚本注入 |
| `description` | 否 | 人类可读描述 |
| `ports` | 是 | Agent 用于端口释放等待和冲突检测 |
| `health_check.type` | 是 | 固定为 `http` |
| `health_check.urls` | 是 | 健康检查 URL 列表 |
| `health_check.strategy` | 是 | `any`（任一通过即健康）或 `all` |
| `health_check.timeout` | 是 | 单次请求超时，单位毫秒 |

## 注意事项

- `name` 字段必须与 `$APP_NAME` 环境变量一致，不能硬编码
- `version` 字段在模板中写 `"__VERSION__"`，打包脚本用 `sed` 替换为实际版本号
- 文件编码必须为 UTF-8（无 BOM）
