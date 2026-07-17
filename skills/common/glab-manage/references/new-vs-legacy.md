# 新老项目判断详细逻辑

## 判断流程

```
Step 1: 检测本地信号
  读取 docs/dev-plan.md（如果存在）
  统计 Issue 字段状态：
    全部为 "#（待创建）" → 新项目信号 +1
    部分有编号           → 老项目信号 +1
    文件不存在           → 中性

Step 2: 检测 GitLab 信号
  GET /api/v4/projects/{id}/milestones
  结果为空（count=0）→ 新项目信号 +1
  结果非空            → 老项目信号 +1

Step 3: 检测用户意图
  用户说"新项目"/"从头开始"/"全量创建" → 新项目信号 +2（权重高）
  用户说"补充"/"新增"/"这期迭代"       → 老项目信号 +2

Step 4: 判定
  新项目信号 > 老项目信号 → 全量创建模式
  老项目信号 > 新项目信号 → 增量维护模式
  信号相等（无法判断）    → 展示差异，询问用户
```

---

## 向用户展示差异时的输出模板

```
无法自动判断项目类型，请选择：

  [1] 全量创建模式（新项目）
      将创建：3 个 Milestone + 12 个 Issue
      适用场景：GitLab 项目是空的，或需要重新初始化

  [2] 增量维护模式（老项目）
      将创建：1 个新 Milestone + 3 个待创建 Issue
      跳过：9 个已有 Issue 编号的 Task
      适用场景：项目已有 Milestone 和 Issue，只需同步新增部分

请输入 1 或 2：
```

---

## 增量模式的去重逻辑

```
Milestone 去重：
  GET 所有已有 Milestone，提取 title 列表
  对每个待创建 Phase：
    标题完全匹配 → 跳过，记录已有 Milestone ID（用于 Issue 关联）
    无匹配 → 创建新 Milestone

Issue 去重：
  GET 所有 opened Issue（state=opened），提取 title 列表
  对每个待创建 Task：
    标题完全匹配 → 跳过，输出"已存在：#xx"
    无匹配 → 创建新 Issue

注意：关闭的 Issue（state=closed）也需要检查，避免重复创建
  GET 时加参数 state=all 获取所有状态
```

---

## 输出格式（增量模式执行后）

```
aic glab-manage — backend-api（增量维护模式）

  Phase 4: aic env 命令  →  Milestone #4 ✓ 创建成功
  
  [Phase 4] 实现 aic env list 命令      →  #45 ✓
  [Phase 4] 实现 aic env add 交互输入   →  #46 ✓
  [Phase 4] 实现 env-required 渲染逻辑  →  #47 ✓

  跳过（已有 Issue）：
    [Phase 1] 实现 SKILL.md frontmatter 解析  →  #12（已有）
    [Phase 2] 实现 GitLab clone/pull          →  #18（已有）
    ...（共 9 个跳过）

  ──────────────────────────────────────────
  新建：1 Milestone，3 Issues
  跳过：9 Issues（已存在）
  回写 dev-plan.md 中...  ✓
  自动 commit：docs: 同步 GitLab Issue 编号到开发计划  ✓
```
