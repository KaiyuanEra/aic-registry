# Context 反模式

| 反模式 | 风险 | 改法 |
|---|---|---|
| 修改已发布 context 但不升级版本 | 制品变更无法从索引版本中识别 | 每次修改至少递增 PATCH |
| 在 `content.md` 添加 front matter | front matter 会被原样注入项目记忆文件 | 元数据只放 `CONTEXT.md` |
| 手改 `contexts/index.yaml` | 下一次 index 生成会覆盖 | 修改 `CONTEXT.md` 后运行 `make index` |
| 提醒用户手工编辑 `contexts/index.yaml` | 容易与 front matter 漂移且会被覆盖 | 运行 `make index` 并检查生成 diff |
| 通用 context 填满项目事实 TODO | 把信息收集成本转嫁给使用者，产物无法直接使用 | 省略未知事实，改写为通用、可执行的核验规则 |
| 默认交付含 TODO 的 context | 安装后仍需二次编写，降低效率 | 默认禁止 TODO；仅显式脚手架模式允许 |
| 猜测 build/test 命令 | agent 会执行不存在或危险的命令 | 要求从目标项目已有文档和配置核验，找不到时报告缺口 |
| 复制 formatter/linter 规则 | 内容膨胀且容易漂移 | 只写工具无法强制的意图和边界 |
| 粘贴大段代码或目录树 | 很快过时并挤占上下文 | 引用稳定路径并说明阅读时机 |
| 写“本季度”“下个 sprint” | 形成无明确失效点的陈旧信息 | 使用可验证状态或删除条件 |
| 环境变量写成 `{{VAR}}` | 不符合 context 模板语法 | 使用 `{{ aic.env.VAR }}` 并声明 `env-vars` |
| 占位符没有同名声明 | context 包的变量契约不完整 | 在 `env-vars` 中补齐完整字段 |
| 声明变量但正文不引用 | 形成无法判断用途的陈旧配置 | 删除声明或补充真实使用位置 |
| `env-required: false` 仍声明或引用变量 | front matter 自相矛盾 | 有变量时改为 `true`，无变量时删除声明和占位符 |
| 在模板中放真实敏感值 | 敏感值会进入版本库 | 模板只保留已声明的占位符 |
| 修改场景整篇重写 | 丢失用户未涉及的约定 | 局部编辑，先展示 diff |
| context 目录名与 `name` 不一致 | 查找、安装和索引语义混乱 | 两者保持完全一致 |
