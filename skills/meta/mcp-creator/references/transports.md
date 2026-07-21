# Transport 与客户端能力

## 能力矩阵

创建源定义时使用以下 registry 能力边界：

| transport | Claude | Codex | Gemini | OpenCode |
|---|---:|---:|---:|---:|
| `stdio` | 支持 | 支持 | 支持 | 支持 |
| `sse` | 支持 | 不支持 | 支持 | 不支持 |
| `streamable-http` | 支持 | 支持 | 支持 | 支持 |

`targets` 中出现不支持当前 transport 的客户端时立即报错。不得删除该 target 后继续，也不得把 `sse` 静默改成 `streamable-http`。

## Adapter 语义

creator 只定义源模型，不直接生成以下文件。这些映射用于检查源字段是否足够，不用于在 registry 中保存客户端专有配置。

| 源模型 | Claude | Codex | Gemini | OpenCode |
|---|---|---|---|---|
| stdio transport | `type: stdio` | stdio server | stdio server | `type: local` |
| stdio command/args | `command` + `args` | 原生命令与参数 | 原生命令与参数 | 合并为 `command` 数组 |
| streamable-http transport | `type: http` | 含 `url` 的 server | `httpUrl` | `type: remote` |
| remote URL | `url` | `url` | `httpUrl` | `url` |
| remote headers | `headers` | `http_headers` | `headers` | `headers` |
| timeout | 对应原生字段 | 秒 | 毫秒 | 毫秒 |

SSE 保留独立 transport 语义，只能面向能力矩阵中明确支持它的客户端。

## Adapter 实现约束

- adapter 只接收已经通过源模型和变量校验的规范化 `MCPServer`。
- 每个 adapter 必须明确拒绝无法表达的字段，不能静默丢弃。
- 配置写入采用增量合并，不覆盖用户未由 aic 管理的其他 server。
- 多目标写入先全部生成成功，再原子提交。
- 具体客户端配置路径、合并算法和版本差异属于 aic 工具，不属于 registry creator skill。
