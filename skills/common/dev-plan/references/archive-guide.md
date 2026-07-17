# Phase 归档操作指导（v2.0）

本文档详细说明如何执行 Phase 级归档，保持 dev-plan.md 长度有界。

---

## 1. 何时触发归档

### 文档大小监控

- **< 300 行**：正常状态，无需归档
- **300–400 行**：黄色警告，可考虑归档已完成 Phase
- **> 400 行**：红色警告，强烈建议立即执行归档

### 用户主动发起

```
触发词：
  "归档 Phase N"
  "Phase N 已完成，精简开发计划"
  "dev-plan 太长了，归档已完成的部分"
  "清理已完成的 Phase"
```

---

## 2. 前置校验（必须全部通过）

### 校验 1：Phase 内所有 Task 状态

**检查内容：** 目标 Phase 的每个 Task 是否都标记为 ✅ 已完成

**执行方式：**
```
1. 打开 dev-plan.md
2. 定位到 "### Phase {N}:" 部分
3. 逐个检查每个 Task 的状态字段
4. 确认全部为 ✅ 已完成
```

**失败处理：**
```
如果存在未完成的 Task：
  ❌ 阻止归档
  输出：
    未完成的 Task：
    - Task N.1: {任务名} - 状态：进行中
    - Task N.3: {任务名} - 状态：待开始
    
    请先完成上述 Task 或手动标记为 ✅ 已完成，再执行归档。
```

### 校验 2：GitLab Milestone 状态

**检查内容：** 对应的 GitLab Milestone 是否已关闭（仅当项目使用 GitLab 且存在对应 Milestone 时执行）

**执行方式：**
```
1. 检查 dev-plan.md 中 Phase {N} 的 Task 是否有 Issue 编号
   → 无 Issue 编号（未使用 GitLab）→ 跳过此校验
2. 在 dev-plan.md 中查找 Phase {N} 的 Milestone 编号
3. 访问 GitLab 项目 → Milestones
4. 查找对应 Milestone，检查状态是否为 "Closed"
```

**失败处理：**
```
如果 Milestone 存在且仍为 "Open"：
  ❌ 阻止归档
  输出：
    GitLab Milestone 未关闭：
    Milestone: Phase 1: 基础数据层 (#1)
    状态：Open
    
    请先在 GitLab 关闭该 Milestone，或执行：
    glab milestone update {milestone_id} --state closed
    
    如确认不需要关闭 Milestone，可跳过此校验继续归档。
```

### 校验 3：后续 Phase 依赖引用

**检查内容：** 剩余 Phase 的 Task 是否引用了目标 Phase 的 Task 编号

**执行方式：**
```
1. 打开 dev-plan.md
2. 定位到目标 Phase 之后的所有 Phase
3. 在每个 Task 的"输入依赖"字段中搜索目标 Phase 的 Task 编号
   例如：搜索 "Task 1.1", "Task 1.2" 等
```

**失败处理：**
```
如果存在依赖引用：
  ❌ 阻止归档
  输出：
    后续 Phase 存在依赖引用：
    - Phase 2, Task 2.1: 输入依赖 → Task 1.3
    - Phase 3, Task 3.2: 输入依赖 → Task 1.5
    
    请先更新这些 Task 的依赖描述（改为"无依赖"或引用其他 Task），
    再执行归档。
```

### 校验 4：归档文件冲突

**检查内容：** `docs/dev-plan-archive/phase-{N}.md` 是否已存在

**执行方式：**
```
1. 检查项目目录结构
2. 查看 docs/dev-plan-archive/ 目录
3. 确认 phase-{N}.md 是否存在
```

**失败处理：**
```
如果文件已存在：
  ❌ 阻止归档
  输出：
    该 Phase 已归档：
    docs/dev-plan-archive/phase-1.md 已存在
    
    请确认是否需要重新归档。
    如需覆盖，请先手动删除旧文件或改用其他 Phase 编号。
```

---

## 3. 执行步骤

全部校验通过后，按以下步骤执行。**中途任一步骤失败则整体回滚。**

### Step 1：创建归档目录

```bash
mkdir -p docs/dev-plan-archive/
```

**检查：** 确认目录已创建

### Step 2：生成归档文件

**文件路径：** `docs/dev-plan-archive/phase-{N}.md`

**文件内容结构：**

```markdown
# Phase {N} 归档记录

归档时间：{YYYY-MM-DD}
完成时间：{实际完成日期}
计划工期：{n} 天
实际工期：{n} 天
关联 Milestone：#{Milestone ID}
Task 完成情况：{M}/{M}

---

### Phase {N}: {阶段名} | 预估工期：{n}天 | 优先级：P{n}

**目标：** {本阶段交付什么，为什么先做这个}

#### Task N.1: {任务名}
- **目标：** {实现什么，验收标准是什么}
- **涉及文件：** `path/to/file.go`, `path/to/other.go`
- **输入依赖：** {依赖什么}
- **预期产出：** {产出什么}
- **预估：** {n} 小时
- **Issue：** #{n}
- **状态：** ✅ 已完成
- **注意：** {边缘情况、技术风险}（可选）

#### Task N.2: {任务名}
...（后续 Task 完整保留）
```

**操作方式：**
```
1. 从 dev-plan.md 中复制目标 Phase 的完整内容
   （从 "### Phase {N}:" 到下一个 "### Phase" 之前）
2. 在文件头部添加元数据（归档时间、完成时间、工期、Milestone、Task 完成情况）
3. 将完整内容写入 docs/dev-plan-archive/phase-{N}.md
```

### Step 3：从 dev-plan.md 删除目标 Phase 块

**操作方式：**
```
1. 打开 dev-plan.md
2. 定位到 "### Phase {N}:" 行
3. 删除从该行到下一个 "### Phase" 之前的全部内容
   （包括 Phase 标题、所有 Task、以及尾部空行）
4. 保留 "### Phase {N+1}:" 及之后的内容
```

**检查：** 确认 dev-plan.md 中不再包含目标 Phase 的内容

### Step 4：更新 dev-plan.md 顶部已归档声明与索引表

**操作方式：**
```
1. 打开 dev-plan.md
2. 定位到文件头部的 "> 最后更新：..." 行
3. 在该行下方添加或更新 "> 已归档：" 行

示例：
> 最后更新：2026-06-01 | 版本：v4 | 状态：进行中
> 已归档：Phase 1（基础数据层）→ docs/dev-plan-archive/phase-1.md
>         Phase 2（Git 仓库与 Cache）→ docs/dev-plan-archive/phase-2.md

4. 定位到 "## 已归档 Phase 索引" 表格
5. 在表格中追加一行：

| Phase 1 | 基础数据层 | 2026-05-12 | 6 | #1-#6 |

   其中：
   - Phase：目标 Phase 编号
   - 阶段名：Phase 的名称
   - 完成时间：实际完成日期
   - Task 数：该 Phase 的 Task 总数
   - Issue 范围：该 Phase 的 Issue 编号范围（如 #1-#6）
```

**检查：** 确认已归档声明和索引表已更新

### Step 5：在变更记录中追加归档记录

**操作方式：**
```
1. 打开 dev-plan.md
2. 定位到 "## 变更记录" 表格
3. 在表格顶部（最新记录处）追加一行：

| v{n} | {YYYY-MM-DD} | Phase {N} 归档 → docs/dev-plan-archive/phase-{N}.md |

4. 如果变更记录超过 5 条，删除最早的一条
```

**检查：** 确认变更记录已追加

### Step 6：输出归档报告

```
✅ Phase {N} 已成功归档

归档文件：docs/dev-plan-archive/phase-{N}.md
dev-plan.md 减少约 {N} 行（从 {old_lines} 行 → {new_lines} 行）
已归档 Phase 索引表已更新：Phase {N} 添加到表格中
当前活跃计划：Phase {M} 到 Phase {K}（共 {total_tasks} 个 Task）

后续操作建议：
1. 执行 git add 和 git commit 提交变更
2. 如需同步到 GitLab，使用 glab-manage skill
3. 如 dev-plan.md 仍超过 400 行，考虑继续归档其他 Phase
```

---

## 4. 回滚处理

如果执行过程中任一步骤失败，执行以下回滚操作：

```
1. 删除已创建的 docs/dev-plan-archive/phase-{N}.md 文件
2. 恢复 dev-plan.md 到执行前的状态
   （如已修改，使用 git checkout dev-plan.md 恢复）
3. 输出错误信息和失败原因
4. 提示用户修复问题后重试
```

---

## 5. 常见问题

### Q1：能否只归档 Phase 内的部分 Task？

**A：** 不能。归档是 Phase 级操作，必须整个 Phase 一起归档。原因：
- Phase 内部分 Task 归档后，dev-plan.md 中出现残缺的 Phase 块
- AI 工具读取时，当前 Phase 的上下文不完整
- 增加了文档维护的复杂度

### Q2：归档后能否恢复？

**A：** 可以。归档文件保存在 `docs/dev-plan-archive/phase-{N}.md` 中，可以手动复制回 dev-plan.md。但建议通过 git 历史查看原始内容。

### Q3：如何查找已归档的 Task？

**A：** 通过 dev-plan.md 顶部的"已归档 Phase 索引"表格查找：
1. 打开 dev-plan.md，查看"已归档 Phase 索引"表格
2. 根据 Issue 范围或阶段名定位到对应 Phase
3. 打开 `docs/dev-plan-archive/phase-{N}.md` 查看完整 Task 内容

### Q4：归档后其他 skill 如何找到 Issue 编号？

**A：** 其他 skill（glab-manage / git-commit）通过 dev-plan.md 中的索引表查找：
1. 先查 dev-plan.md 活跃 Phase 中的 Task
2. 未找到 → 查 dev-plan.md 顶部的"已归档 Phase 索引"表格，根据 Issue 范围定位 phase-N.md
3. 打开对应 phase-N.md 获取具体 Issue 编号
4. 仍未找到 → 提示用户手动提供

---

## 6. 检查清单

执行归档前，确认以下项目：

- [ ] 目标 Phase 的所有 Task 都标记为 ✅ 已完成
- [ ] 对应的 GitLab Milestone 已关闭
- [ ] 后续 Phase 的 Task 不依赖目标 Phase 的 Task
- [ ] `docs/dev-plan-archive/phase-{N}.md` 不存在（或已备份）
- [ ] dev-plan.md 已备份或在 git 中（便于回滚）
- [ ] 有足够的磁盘空间创建新文件

执行归档后，确认以下项目：

- [ ] `docs/dev-plan-archive/phase-{N}.md` 已创建
- [ ] dev-plan.md 中不再包含目标 Phase 的内容
- [ ] 已归档声明（文件头部 `> 已归档：`）已更新
- [ ] 已归档 Phase 索引表已追加新行
- [ ] 变更记录已追加
- [ ] dev-plan.md 行数已减少
- [ ] 文件格式正确（Markdown 语法无误）
