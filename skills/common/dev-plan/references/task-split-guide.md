# 任务拆分详细指导

## 粒度原则

**黄金标准：一个 Task = 2–8 小时 + 1–3 个具体文件改动**

| 范围 | 处置 |
|------|------|
| < 2 小时 | 可合并到相邻 Task，减少管理开销 |
| 2–8 小时 | 理想粒度 ✅ |
| > 8 小时 | 必须继续拆分，拆到满足标准为止 |

---

## 拆分维度选择

按以下优先级选择拆分维度，选第一个适用的：

1. **文件边界** — 改动文件不重叠的工作，天然隔离，优先按此拆
2. **层次边界** — 数据层 / 业务层 / 接口层分开，依赖方向清晰
3. **功能边界** — 读操作 / 写操作 / 校验逻辑分开
4. **阶段边界** — "基础实现" 和 "错误处理 / 边缘情况" 分开

---

## Task 字段填写规范

### 任务名（必须是动词短语）

```
✅ 好的任务名：
  实现 ParseSkill() 函数
  添加 env-vars 字段校验
  修复 symlink 创建时的竞态条件

❌ 差的任务名：
  Parser 模块           ← 名词，不说明做什么
  SKILL.md 相关工作     ← 范围不清
  优化                  ← 没有主语
```

### 涉及文件（必须是具体路径）

```
✅ 具体路径：
  internal/skill/parser.go
  internal/skill/model.go

❌ 模糊表达：
  相关的 Go 文件
  internal/skill/ 下的文件
```

### 输入依赖

```
无前置依赖：
  输入：无依赖（基础模块，可独立开始）

有前置依赖：
  输入：Task 1.2（config 模块）完成后才能开始

依赖外部数据：
  输入：GitLab API 可访问，GITLAB_TOKEN 已配置
```

### 输出产物（要具体到接口）

```
✅ 具体产出：
  输出：ParseSkill(path string) (*Skill, error) 函数
  输出：GET /api/v4/skills/:name 接口可调用
  输出：validate.sh 脚本对合规 SKILL.md 输出 exit 0

❌ 模糊产出：
  输出：功能实现完成
  输出：代码写好
```

### 验收标准（必须可被 AI 自验）

```
✅ 可自验：
  go test ./internal/skill/... 通过
  echo $? 返回 0
  curl 接口返回 200 且响应体包含 name 字段

❌ 无法自验：
  代码逻辑正确
  功能符合预期（谁来判断？）
```

---

## 依赖关系处理

同一 Phase 内尽量减少 Task 间的强依赖，便于并行开发：

```
推荐：
  Task 1.1 和 Task 1.2 都无依赖 → 可并行开始

需要注意：
  Task 1.3 依赖 Task 1.1 → 明确写在"输入"字段
  不需要画依赖图，文字说明即可
```

跨 Phase 依赖：下一 Phase 默认依赖上一 Phase 全部完成，无需在每个 Task 中单独声明。

---

## 拆分示例（aic 项目）

**原始任务（过大，需拆分）：**
> 实现 aic install 命令

**拆分结果：**

```
Task 2.1: 实现 .aicrc 读写
- 涉及文件：internal/config/project.go
- 输入：无依赖
- 输出：ReadAicrc() / WriteAicrc() 函数
- 预估：3小时

Task 2.2: 实现 SKILL.md frontmatter 解析
- 涉及文件：internal/skill/parser.go, internal/skill/model.go
- 输入：无依赖
- 输出：ParseSkill(path string) (*Skill, error)
- 预估：3小时

Task 2.3: 实现 GitLab 仓库 clone/pull
- 涉及文件：internal/registry/client.go
- 输入：Task 2.1 完成（需要读取 registry_url 配置）
- 输出：FetchRegistry(branch string) error
- 预估：4小时

Task 2.4: 实现软链接创建逻辑
- 涉及文件：internal/linker/linker.go, internal/linker/paths.go
- 输入：Task 2.2 完成（需要解析后的 Skill 结构）
- 输出：LinkSkill(skill *Skill, tools []string) error
- 预估：4小时

Task 2.5: 组装 aic install 命令入口
- 涉及文件：cmd/aic/main.go
- 输入：Task 2.1 / 2.2 / 2.3 / 2.4 全部完成
- 输出：aic install <name>[@version] 可执行
- 预估：2小时
```
