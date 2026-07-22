---
name: aic-contexts-creator
version: 1.5.0
description: >
  为 context registry 创建、迁移和增量更新按开发阶段设计的项目级长期记忆 context 包，
  产出并校验 contexts/<context-name>/CONTEXT.md 与 content.md，递增版本并同步 contexts/index.yaml。
  Use when 用户要求编写或规范 CLAUDE.md、AGENTS.md、Agents.md、项目记忆文件、项目上下文，
  将旧记忆迁移成 registry context，切换孵化/迭代/维护/重构阶段规范，或创建类似
  contexts/project-coding-guideline 的工程。 Do NOT use for 普通业务文档、一次性会话提示词、
  skill 编写，或修改 context registry 之外的工具实现。
tags: [context-authoring, meta, project-memory]
env-required: false
---

# Contexts Creator

把用户提供的事实整理成 registry context 包。每个阶段可以作为独立的、可版本化的 context 目录存在。

## 开始前

1. 确认当前仓库包含 `contexts/` 和 `scripts/indexgen/indexgen.py`。缺少时停止，并说明当前仓库不是受支持的 context registry 布局。
2. 阅读 [context 包契约](references/context-package-contract.md)。涉及变量时必须再读 [变量声明与引用](references/context-variables.md)；涉及正文结构时读 [标准模板](references/context-template.md)；审查或迁移旧文件时同时读 [反模式](references/anti-patterns.md)。
3. 判断产物类型：通用可复用 context、项目定制 context，或用户明确要求的待填写脚手架；同时判断是首次创建、迁移、增量修改还是切换阶段。
4. 只读取用户明确提供的描述、文档和旧记忆文件。除非用户另行要求，不自动扫描代码库推断技术栈、命令或目录结构。

## 收集事实

从已有材料抽取并记录来源：

- 当前阶段：`incubation`、`iteration`、`maintenance` 或 `refactor`
- 项目定位、使用者和范围边界
- 技术栈、架构边界和真实路径
- 已确认的构建、测试、lint、启动命令
- linter 无法强制的约定、高危操作和完成标准
- 应引用的外部文档
- 是否需要环境变量模板占位符

通用可复用 context 只提炼跨项目成立的阶段规则，不要求项目技术栈、命令或目录等定制信息。项目定制 context 只询问缺失且会改变产物的事项，并在生成前解决必要问题。不得猜测命令、路径、模块、依赖版本或工具支持。

**默认最终产物禁止出现 TODO、空白占位符或“待用户确认”。** 缺少非必要事实时，省略该事实并保留可直接执行的通用规则。只有用户明确要求生成模板或脚手架时，才允许占位符。

## 选择阶段侧重

保持相同的七段骨架，只改变内容权重：

| 阶段 | 侧重 | 约束 |
|---|---|---|
| `incubation` | 项目定位、常用命令 | 保持轻量，明确原型边界，避免提前固化生产规范 |
| `iteration` | 代码规范、验证流程、禁止事项 | 控制膨胀，把细节移到稳定的外部文档 |
| `maintenance` | 高危操作、验证流程 | 突出发布、密钥和迁移边界，删除探索期遗留说明 |
| `refactor` | 架构、外部文档 | 写清新旧边界；临时规则必须带可验证的失效条件 |

未指定名称时，按阶段使用 `01-incubation-prototype`、`02-iteration-evolution`、`03-maintenance-stable`、`04-refactor-evolution`。只生成用户当前需要的阶段；不要为了完整目录一次创建四个空包。

## 生成或修改

1. 在 `contexts/<context-name>/` 创建 `CONTEXT.md` 和 `content.md`；`CONTEXT.md.name` 必须与目录名一致，`content.md` 不添加 YAML front matter。
2. 使用标准七段骨架，尽量控制在 200 行内；用已确认的真实路径加一句说明代替粘贴代码。没有真实路径时写通用的文档发现与核验规则，不生成路径占位符。
3. 只写 linter/formatter 无法自动保证的规则；非显而易见的规则说明原因。
4. 避免“本季度”“下个 sprint”等易过期时间描述。
5. 需要变量时，按 [变量声明与引用](references/context-variables.md) 同时维护 `CONTEXT.md.env-vars` 和 `content.md` 占位符。不得使用未声明变量，不得留下无用途声明，不得写入真实密钥或敏感值。
   **变量名必须匹配 `^[A-Z][A-Z0-9_]*$`，区分大小写，同一声明中不得重复。**
6. 按 [context 包契约](references/context-package-contract.md) 创建或更新 `CONTEXT.md`。新包从 `1.0.0` 开始；任何已发布 context 的修改都必须递增版本，默认至少升 PATCH。
7. 修改已有包时仅做局部编辑，保留未涉及内容。落盘前展示 diff 并等待用户确认；用户已明确要求直接修改时，视为已确认。
8. 运行 `make index` 重新生成 `contexts/index.yaml`；不要让用户手工维护生成文件。生成器已递归扫描 `contexts/**/CONTEXT.md`，无需为新增 context 修改 `scripts/indexgen/indexgen.py`。registry 版本取根目录 `VERSION`，context 条目的版本取 `CONTEXT.md`。

版本选择：错别字、事实修正或不改变结构的规则修改升 PATCH；新增区块能力或显著扩展规则升 MINOR；不兼容的 context 契约变化升 MAJOR。不得只修改 `content.md` 而沿用旧版本。

## 验证与交付

运行：

```bash
make index
skills/meta/contexts-creator/scripts/validate-context.sh . <context-name>
make validate
git diff -- contexts/<context-name> contexts/index.yaml
```

逐项检查：七段骨架存在；默认正文不含 TODO 或空白占位符；事实有来源；正文无 front matter；变量声明和占位符一致；`contexts/index.yaml` 的 version、description、path 与 `CONTEXT.md` 一致；diff 不包含无关改动。

交付时说明所选阶段、context 名称、修改文件、旧版本到新版本的变化和验证结果。明确告知用户 `contexts/index.yaml` 已由生成器刷新，无需手工维护。若用户明确要求脚手架，才单独汇总保留的占位符。
