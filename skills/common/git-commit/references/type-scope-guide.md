# type/scope 选择指南

## type 选择决策树

```
这次提交...

改变了功能行为？
  是 → 是修复已有 bug？
         是 → fix
         否 → feat
  否 → 改动了测试文件？
         是 → test
         否 → 改动了文档 / 注释？
                是 → docs
                否 → 改动了构建 / 配置 / 依赖？
                       是 → chore
                       否 → 重构了代码（不改行为）？
                              是 → refactor
                              否 → 提升了性能？
                                     是 → perf
                                     否 → chore（兜底）
```

---

## type 使用边界说明

### feat vs fix

```
feat：之前不存在这个功能，现在加了
fix：之前有这个功能但行为不对，现在修对了

边界模糊时：
  "添加了对 XXX 边缘情况的处理" → fix（完善已有功能的正确性）
  "添加了全新的 XXX 命令" → feat
```

### refactor vs fix

```
refactor：外部行为完全不变，只是内部结构变了
fix：外部行为变了（即使改动很小）

判断方法：测试用例是否需要修改？
  不需要修改 → refactor
  需要修改   → fix 或 feat
```

### chore vs docs

```
docs：改动的是 .md / 注释 / 文档生成配置
chore：改动的是 Makefile / CI 配置 / .gitignore / 依赖版本

混合情况：以改动量大的为准，或拆分为两次 commit
```

---

## scope 命名规范

scope 来源：项目的模块结构，不是文件名。

### aic 项目的 scope

| scope | 对应模块 | 示例文件 |
|-------|---------|----------|
| `install` | 安装命令 | cmd/aic/main.go（install 分支）|
| `sync` | 同步命令 | cmd/aic/main.go（sync 分支）|
| `list` | 列表/浏览 TUI | internal/ui/list/ |
| `env` | 环境变量管理 | internal/env/ |
| `config` | 配置读写 | internal/config/ |
| `registry` | GitLab 仓库操作 | internal/registry/ |
| `linker` | 软链接管理 | internal/linker/ |
| `parser` | SKILL.md 解析 | internal/skill/parser.go |
| `ui` | TUI 通用组件 | internal/ui/ |

### 通用 scope（任何项目适用）

| scope | 用途 |
|-------|------|
| `api` | API 接口层 |
| `db` | 数据库相关 |
| `auth` | 认证授权 |
| `config` | 配置管理 |

### 何时省略 scope

变更范围跨越多个模块，或是全局性修改时，scope 可以省略：

```
docs: 更新开发计划，同步 Phase 2 的 Issue 编号
chore: 升级所有依赖到最新版本
refactor: 统一错误处理方式
```

---

## 特殊场景

### Merge / Squash commit

合并分支时的 commit，type 选择合并内容的主体类型，正文可列出包含的 commit：

```
feat(install): 完成 aic install 命令全部功能

包含：
- feat(parser): 实现 SKILL.md frontmatter 解析
- feat(registry): 实现 GitLab clone/pull
- feat(linker): 实现软链接创建
- test(install): 添加 install 命令集成测试

Closes #5, #6, #7, #8
```

### 回滚 commit

```
revert: feat(linker): 实现软链接创建

原因：引入了竞态条件，暂时回滚等待修复。
Reverts commit abc1234.
Refs #15
```
