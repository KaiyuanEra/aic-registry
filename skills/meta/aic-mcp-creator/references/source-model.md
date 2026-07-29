# MCP 源模型契约

## 目录结构

每个 MCP server 是一个独立的 registry 包：

```text
mcp-servers/<name>/
└── MCP-SERVER.md
```

`MCP-SERVER.md` 第一行必须是 `---`，并以另一个独占一行的 `---` 结束 frontmatter。正文只用于详细说明，不参与配置生成。

## 公共字段

| 字段 | 必填 | 规则 |
|---|---|---|
| `name` | 是 | 匹配 `^[a-z0-9]+(-[a-z0-9]+)*$`，与目录名一致 |
| `version` | 是 | `MAJOR.MINOR.PATCH`，不带 `v` |
| `description` | 是 | 非空的单行或折叠字符串 |
| `transport` | 是 | `stdio`、`sse`、`streamable-http` 三选一 |
| `targets` | 是 | 非空、无重复，只允许 `claude/codex/gemini/opencode` |
| `env-required` | 是 | YAML 布尔值；使用变量时为 `true` |
| `env-vars` | 条件必填 | 变量声明列表，`target` 固定为 `mcp` |
| `tags` | 否 | 用于 registry 检索的字符串列表 |
| `timeout` | 否 | 正数 Go duration，例如 `5s`、`30s`、`2m` |
| `platforms` | 否 | 仅 `stdio` 可用，按 GOOS 覆盖当前平台的 `command` / `args` |

未知字段必须报错，避免拼写错误被静默忽略。

## Transport 字段

| transport | 必填 | 可选 | 禁止 |
|---|---|---|---|
| `stdio` | `command` | `args`、`cwd`、`env`、`timeout`、`platforms` | `url`、`headers` |
| `sse` | `url` | `headers`、`timeout` | `command`、`args`、`cwd`、`env` |
| `streamable-http` | `url` | `headers`、`timeout` | `command`、`args`、`cwd`、`env` |

字段类型：

- `command`、`cwd`、`url`、`timeout` 是非空字符串。
- `args` 是字符串列表，保持顺序。
- `env` 和 `headers` 是字符串到字符串的映射。
- `url` 必须使用 `http` 或 `https` scheme。
- `timeout` 表达源模型中的超时，由 adapter 转换为目标客户端使用的单位；不要在源文件中预先写成秒数或毫秒数。

## STDIO 平台覆盖

`stdio` MCP 可以声明平台差异：

```yaml
command: codegraph
args:
  - serve
  - --mcp
platforms:
  windows:
    command: codegraph.exe
    args:
      - serve
      - --mcp
```

语义：

- 顶层 `command` / `args` 是默认配置，适用于 Linux/macOS，也作为 fallback。
- `platforms.<GOOS>.command` / `args` 只覆盖当前平台；未命中时使用顶层配置。
- 初期允许 `windows`、`linux`、`darwin`，registry 不要求每个平台都声明。
- 只支持 `command` 和 `args`，不得在 `platforms` 下声明 `shell`、`shell_args`、`cwd`、`env` 或客户端专属字段。
- `args` 是整体替换；`args: []` 表示当前平台无参数，未写 `args` 才 fallback 顶层。
- 不自动补 `.exe` / `.cmd`，不自动 shell wrap，不做路径转换。Windows 启动语义必须来自 MCP server 分发者或用户明确提供。

## 解析和渲染边界

正确顺序是：

```text
解析 YAML frontmatter
  -> 构造 transport 判别联合类型
  -> 校验 transport 专属字段
  -> 对 stdio 选择当前平台 command/args 覆盖
  -> 解析并校验变量
  -> 校验 targets 能力
  -> 所有 adapter 生成成功
  -> 原子增量写入所有目标配置
```

变量只能在 YAML 成功解析后，对允许字段的字符串值逐项替换。不要对原始 YAML 文本替换变量；变量值中的引号、换行或特殊字符可能破坏 YAML 结构。

一次安装涉及多个客户端时，必须先完成所有 adapter 的生成与校验，再统一提交写入，避免部分客户端成功、部分客户端失败。

## 正文

正文至少包含一个标题和用途说明，可以记录安装前提、认证来源、安全注意事项和服务端文档入口。正文：

- 不参与 MCP 配置生成。
- 不作为 frontmatter 缺失字段的补充来源。
- 不保存 token、密码或其他真实敏感值。
- 默认不包含 TODO、空白模板或待确认项。

## 版本和索引

- 新建包从 `1.0.0` 开始。
- 正文、targets、transport 配置、变量声明或其他生效元数据发生变化时必须递增版本。
- 小修升 PATCH；向后兼容的能力扩展升 MINOR；不兼容契约变化升 MAJOR。
- 修改后运行 `make index`，不要手工编辑 `mcp-servers/index.yaml`。
- 索引根键为 `mcp_servers`，条目包含 `name`、`version`、`description`、可选 `tags` 和 `path`。
