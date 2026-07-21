---
name: mcp-creator
version: 1.0.0
description: >
  为 aic registry 创建、审查和增量更新结构化 MCP server 包，生成并校验
  mcp-servers/<name>/MCP-SERVER.md，处理 stdio、SSE 和 Streamable HTTP transport、
  环境变量占位符、目标客户端能力、版本递增及 mcp-servers/index.yaml。
  Use when 用户要求新增 MCP server 定义、编写 MCP-SERVER.md、把 MCP 配置收录进 registry、
  修改已有 MCP 源模型，或检查 MCP transport 与 Claude/Codex/Gemini/OpenCode 的兼容性。
  Do NOT use for 实现 aic 客户端 parser/adapter、直接改写 IDE 原生 MCP 配置、启动 MCP server，
  或编写普通 Skill、Context 和一次性 MCP 使用说明。
tags: [mcp, meta, registry-authoring]
env-required: false
---

# MCP Creator

创建一个可版本化的 MCP 源定义。一个 MCP 包只有一个 `MCP-SERVER.md`；YAML frontmatter 是配置的唯一数据源，正文只写人类可读说明。

## 开始前

1. 确认仓库包含 `mcp-servers/` 或 `scripts/indexgen/indexgen.py`；两者都没有时停止，说明当前仓库不是支持的 registry 布局。
2. 阅读 [源模型契约](references/source-model.md)。涉及变量时再读 [变量规则](references/variables.md)；选择 transport 或 targets 时读 [transport 与客户端能力](references/transports.md)。需要完整样例时读 [示例](references/examples.md)。
3. 判断任务是首次创建、增量修改还是审查。只创建或修改 registry 源定义，不实现 aic parser、adapter 或客户端写入逻辑。
4. 从用户提供的命令、URL、header、目标客户端和说明中提取事实。不得猜测命令参数、认证 header、私有地址或客户端支持能力。

## 生成或修改

1. 创建 `mcp-servers/<name>/MCP-SERVER.md`。目录名、frontmatter `name` 和索引名称必须一致，并匹配 `^[a-z0-9]+(-[a-z0-9]+)*$`。
2. 只声明一个 `transport`：`stdio`、`sse` 或 `streamable-http`。严格应用对应字段的必填、允许和禁止规则。
3. `targets` 只使用 `claude`、`codex`、`gemini`、`opencode`，不得重复。写文件前按能力矩阵拒绝不支持的组合；绝不在 SSE 与 Streamable HTTP 之间自动转换。
4. 把结构化配置全部放进 frontmatter。正文至少写清用途和必要的运行前提，但不得作为 adapter 输入，也不得重复维护可执行配置。
5. 对变量使用 `{{ aic.env.NAME }}`，只允许出现在 `command`、`args`、`cwd`、`env`、`url`、`headers` 的字符串值中。变量必须在 `env-vars` 声明，名称匹配 `^[A-Z][A-Z0-9_]*$`、区分大小写、不得重复，且 `target` 固定为 `mcp`。
6. 变量替换的语义是“先解析 YAML，再替换允许字段的字符串值”。不得建议或生成先替换原始 YAML 再解析的流程。
7. 新包从 `1.0.0` 开始。修改已发布包的正文或任一 frontmatter 字段时必须递增版本：小修升 PATCH，向后兼容的能力扩展升 MINOR，不兼容契约变化升 MAJOR。
8. 默认产物不得包含 TODO、空白占位符或“待用户确认”。信息不足且会影响运行配置时先询问用户；非必要信息直接省略。只有用户明确要求脚手架时才允许保留占位符。
9. 修改已有包时只做局部编辑，保留未涉及字段和正文。用户明确要求直接修改时即可落盘，否则先说明将改变的字段。

## 刷新与验证

完成文件后运行：

```bash
make index
python3 skills/meta/mcp-creator/scripts/validate_mcp_server.py . <name>
make validate
git diff -- mcp-servers/<name> mcp-servers/index.yaml skills/index.yaml
```

`mcp-servers/index.yaml` 是生成文件，不让用户手工维护。生成器递归扫描 `mcp-servers/**/MCP-SERVER.md`，条目版本来自源文件，registry 版本来自根目录 `VERSION`。

验证必须覆盖：YAML 无重复键；公共字段完整；transport 字段互斥；target 能力匹配；timeout 是正数 Go duration；变量声明与引用一一对应；正文不参与配置；已有包版本已递增；索引的 version、description 和 path 与源文件一致。

## 交付

说明 MCP 名称、transport、targets、版本变化、修改文件和验证结果。明确说明索引已由生成器刷新。不要声称已经生成客户端原生配置；那属于 aic adapter 的职责。
