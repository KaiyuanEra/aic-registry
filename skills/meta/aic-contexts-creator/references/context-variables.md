# Context 变量声明与引用

变量声明属于 `CONTEXT.md` front matter，变量引用属于该 context 的正文文件。两处必须成对维护。

## 完整示例

`CONTEXT.md`：

```yaml
---
name: project-coding-guideline
version: 1.0.1
description: Default AI coding guideline injected into project context files.
targets:
  - CLAUDE.md
  - AGENTS.md
  - Agents.md
content: content.md
env-required: true
env-vars:
  - name: AIC_AVAILABLE_CLI_TOOLS
    description: Local command-line tools available to the model.
    required: false
    target: context
---
```

`content.md`：

````markdown
本项目声明可用的命令行工具：

```text
{{ aic.env.AIC_AVAILABLE_CLI_TOOLS }}
```
````

## Front Matter 字段

### `env-required`

- `true`：该 context 使用变量，必须同时提供非空 `env-vars`。
- `false`：该 context 不使用变量，不应包含 `env-vars` 或变量占位符。

`env-required` 描述的是整个 context 是否使用变量，不等同于单个变量的 `required`。

### `env-vars`

每个变量项使用以下字段：

| 字段 | 必填 | 规则 |
|---|---|---|
| `name` | 是 | `^[A-Z][A-Z0-9_]*$`，在同一 context 内唯一 |
| `description` | 是 | 说明变量提供什么信息以及正文如何使用，不写真实值 |
| `required` | 是 | YAML 布尔值 `true` 或 `false`，表示是否必须提供该变量 |
| `default` | 否 | 缺少外部值时使用的非敏感默认值；不能放 token、密码或环境专属地址 |
| `target` | 是 | context 变量固定写 `context` |

不要因为变量标记为 `required: false` 就编造默认值。确有稳定、非敏感且跨项目适用的默认值时才声明 `default`。

### 变量名硬性规则

Context 与 Skill 使用完全相同的变量名规则：

```text
^[A-Z][A-Z0-9_]*$
```

- 必须以大写字母开头。
- 后续只能使用大写字母、数字和下划线。
- 区分大小写。
- 不允许小写字母、连字符、点号或空格。
- 不允许数字或下划线开头。
- 同一 `env-vars` 声明中不得重复。

合法示例：

```text
API_KEY
API_BASE_URL
AIC_AVAILABLE_CLI_TOOLS
MODEL_V2_ENDPOINT
```

非法示例：

```text
api_key
2FA_TOKEN
API-KEY
API.KEY
_API_KEY
```

## 正文占位符

标准语法：

```text
{{ aic.env.VAR_NAME }}
```

允许在大括号内增加空格，例如 `{{aic.env.VAR_NAME}}`，但统一输出带空格的标准形式。变量名必须与 `env-vars[].name` 完全一致并区分大小写。

以下写法无效：

```text
{{ VAR_NAME }}
{{ env.VAR_NAME }}
$VAR_NAME
${VAR_NAME}
{{ aic.env.var_name }}
```

## 一致性规则

生成或修改 context 时必须同时检查：

1. 每个 `{{ aic.env.NAME }}` 都有且只有一个同名 `env-vars` 声明。
2. 每个 `env-vars` 声明都至少在正文中引用一次；不再使用时删除声明。
3. 存在任何声明或占位符时，`env-required` 为 `true`。
4. `env-required: true` 时 `env-vars` 非空。
5. `env-required: false` 时不存在 `env-vars` 和占位符。
6. 新增、删除或修改变量声明属于 context 制品变更，必须递增 `version` 并重新生成索引。
7. 变量值永远不写入 registry；registry 只保存声明和占位符。

## 修改示例

新增 `PROJECT_TEST_COMMAND` 时，应在同一次修改中完成：

```yaml
env-required: true
env-vars:
  - name: PROJECT_TEST_COMMAND
    description: Verified command used to run the project test suite.
    required: true
    target: context
```

并在 `content.md` 引用：

```text
{{ aic.env.PROJECT_TEST_COMMAND }}
```

最后递增 `CONTEXT.md.version`，运行 `make index`，再执行 context 校验脚本。
