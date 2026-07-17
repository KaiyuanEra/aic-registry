# Commit Message 示例库

## feat — 新功能

```
feat(install): 实现从 GitLab 拉取 skill 并创建软链接

支持 aic install <name>[@version] 语法，
从 git@git.ifogging.cn 拉取指定版本到本地 cache，
并在 .agents/skills/ 和工具专有路径创建软链接。

Closes #5
```

```
feat(env): 新增 aic env add 命令支持密码输入不回显

使用 bubbles/textinput 的 EchoModePassword 模式，
防止终端截屏时泄露敏感变量值。

Closes #23
```

```
feat(list): 实现 aic list 主界面 TUI
```

---

## fix — 修复 bug

```
fix(sync): 修复 env-required skill 变量缺失时未阻断的问题

原有逻辑只输出 warning 但继续创建软链接，
导致渲染副本包含未替换的 {{VAR}} 被 AI 工具加载。
改为检测到缺失变量时立即返回错误并阻断链接创建。

Closes #31
```

```
fix(linker): 修复并发创建软链接时的竞态条件
```

---

## refactor — 重构

```
refactor(registry): 将 clone 和 pull 逻辑拆分为独立函数

原来单个 FetchRegistry() 函数处理两种情况，
导致测试难以隔离。拆分后各自独立可测。
```

---

## docs — 文档

```
docs: 同步 GitLab Issue 编号到开发计划

由 aic glab-manage 自动生成。
```

```
docs(dev-plan): 新增 Phase 4（aic env 命令），3 个 Task

包含：aic env list / add / check 三个子命令的拆分。
v3 → v4
```

---

## chore — 工程配置

```
chore: 升级 go-git/v5 到 v5.12.0

修复了之前版本在 SSH 连接时的内存泄漏问题。
```

```
chore(ci): 添加 darwin/arm64 交叉编译目标
```

---

## test — 测试

```
test(parser): 添加 frontmatter 解析的边界情况测试

覆盖：version 格式非法、env-vars 为空、name 含大写字母。
```

---

## 多文件变更（跨模块）

```
feat(install): 完成 install 命令端到端流程

串联 registry.FetchRegistry() → skill.ParseSkill() →
linker.LinkSkill()，实现完整的安装流程。
新增集成测试覆盖正常安装和 env-required 两种场景。

Closes #5, #6, #7
```

---

## 新项目简化模式（无 Issue）

```
feat(parser): 实现 SKILL.md frontmatter 解析
```

```
fix: 修复配置文件路径在 HOME 含空格时解析失败
```

```
docs: 初始化项目 README
```

---

## 常见错误写法对照

```
❌ update code             → ✅ fix(linker): 修复软链接目标路径错误
❌ 修改了一些东西          → ✅ refactor(config): 提取配置读取逻辑为独立函数
❌ feat: 功能完成           → ✅ feat(install): 实现 aic install 命令核心流程
❌ fix bug                 → ✅ fix(sync): 修复 BROKEN 状态 skill 重建链接失败
❌ WIP                     → ✅ 不提交 WIP，提交可运行的最小单元
```
