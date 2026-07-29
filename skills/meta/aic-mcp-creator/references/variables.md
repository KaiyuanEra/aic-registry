# MCP 变量声明与引用

## 声明格式

变量在 `MCP-SERVER.md` frontmatter 的 `env-vars` 中声明：

```yaml
env-required: true
env-vars:
  - name: MCP_TOKEN
    description: Access token sent in the MCP Authorization header.
    required: true
    target: mcp
```

每个变量项支持：

| 字段 | 必填 | 规则 |
|---|---|---|
| `name` | 是 | 匹配 `^[A-Z][A-Z0-9_]*$`，同一包内唯一 |
| `description` | 是 | 说明用途，不包含真实值 |
| `required` | 是 | YAML 布尔值 |
| `target` | 是 | 固定为 `mcp` |
| `default` | 否 | 仅允许稳定、非敏感的字符串默认值 |

变量名区分大小写。合法示例为 `API_KEY`、`API_BASE_URL`、`AIC_AVAILABLE_CLI_TOOLS`、`MODEL_V2_ENDPOINT`；`api_key`、`2FA_TOKEN`、`API-KEY`、`API.KEY`、`_API_KEY` 均非法。

## 引用格式

标准占位符为：

```text
{{ aic.env.MCP_TOKEN }}
```

只允许在以下字段的字符串值中引用：

- `command`
- `args` 的元素
- `cwd`
- `env` 的值
- `url`
- `headers` 的值
- `platforms.<goos>.command`
- `platforms.<goos>.args` 的元素

不允许在键名、`name`、`version`、`description`、`transport`、`targets`、`timeout`、变量声明或 Markdown 正文中引用。

## 一致性规则

1. 每个占位符必须有且只有一个同名声明。
2. 每个声明必须至少被允许字段引用一次。
3. 存在声明或占位符时，`env-required` 必须为 `true`。
4. `env-required: true` 时 `env-vars` 必须非空。
5. `env-required: false` 时不得出现 `env-vars` 或占位符。
6. 变量先由项目 env 解析，再回退到全局 env；registry 不保存解析值。
7. 变量解析完成前不得写入任何客户端配置。
8. `required: true` 且缺值时停止整个多目标安装；不得留下部分写入。
9. `default` 不得保存 token、密码、私有地址或环境专属值。
