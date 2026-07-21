# Context 包契约

## 目录结构

每个 context 是一个独立目录：

```text
contexts/<context-name>/
├── CONTEXT.md
└── content.md
```

阶段 context 的默认名称：

| 阶段 | context-name |
|---|---|
| 孵化与原型 | `01-incubation-prototype` |
| 迭代与业务演进 | `02-iteration-evolution` |
| 维护与稳定运行 | `03-maintenance-stable` |
| 重构与演进 | `04-refactor-evolution` |

已有 context 保持原名称。除非用户要求重命名，不要通过创建新目录代替版本升级。

## CONTEXT.md

第一行必须是 `---`，并存在独占一行的结束 `---`：

```yaml
---
name: 02-iteration-evolution
version: 1.0.0
description: Project-level AI guidance for iteration and business evolution.
targets:
  - CLAUDE.md
  - AGENTS.md
  - GEMINI.md
content: content.md
env-required: false
---

# Iteration and Evolution Context

Project-level long-term memory for the iteration stage.
```

硬性要求：

- `name` 非空，使用小写字母、数字和连字符，并与目录名完全一致。
- `version` 使用 `MAJOR.MINOR.PATCH`，不带 `v`。
- `description` 非空；`scripts/indexgen/indexgen.py` 会将其汇总到索引。
- `targets` 至少包含一个目标文件；保留用户选择，不擅自增加或删除。
- `content` 使用包内相对文件名，默认 `content.md`，不得使用绝对路径或 `..`。
- `env-required` 只能是布尔值；为 `true` 时 `env-vars` 不能为空。

环境变量声明示例：

```yaml
env-required: true
env-vars:
  - name: AIC_AVAILABLE_CLI_TOOLS
    description: Local command-line tools available to the model.
    required: false
    target: context
```

变量字段含义、占位符语法和一致性规则见 [变量声明与引用](context-variables.md)。只要 `content.md` 使用变量，就必须同时维护该声明。

## 版本规则

把 context 当作 registry 中的发布制品：

- 新建 context：从 `1.0.0` 开始。
- 修改正文、targets、环境变量声明或其他生效元数据：必须递增版本。
- 小范围规则修正或事实修正：PATCH。
- 新增能力、区块或显著扩展阶段规则：MINOR。
- 不兼容的 front matter 或模板契约：MAJOR。

即使只是修正错别字，也至少递增 PATCH，使制品变更与索引版本保持可追踪。修改前记录旧版本，交付时明确报告 `old -> new`。

## content.md

- 只放项目级长期记忆的 Markdown 正文，不带 YAML front matter。
- 变量按 [变量声明与引用](context-variables.md) 定义和使用。
- 不放真实 token、密码、密钥或私有地址。

## contexts/index.yaml

`contexts/index.yaml` 是生成文件，不由用户手工维护。完成 context 及版本修改后运行：

```bash
make index
```

现有 `scripts/indexgen/indexgen.py` 已经：

1. 递归扫描 `contexts/**/CONTEXT.md`；
2. 读取 `name`、`version`、`description` 和可选 `tags`；
3. 以 context 目录计算 `path`；
4. 将结果写入 `contexts/index.yaml`。

因此新增或修改普通 context 时无需改 indexgen。仅当 registry 要在索引中增加新字段、改变多版本保留策略或调整目录发现规则时，才修改生成器。

索引条目示例：

```yaml
registry_version: "v0.1.0"
contexts:
    - name: "02-iteration-evolution"
      version: "1.1.0"
      description: "Project-level AI guidance for iteration and business evolution."
      path: "contexts/02-iteration-evolution"
```

- `registry_version` 来自仓库根目录 `VERSION`。
- 条目元数据来自 `CONTEXT.md`。
- 运行生成器后必须检查条目版本和 path 与 context 包一致。
- 当前生成器对重复的 `(name, version)` 静默保留第一次扫描到的条目；创建包时应主动避免重复组合。
