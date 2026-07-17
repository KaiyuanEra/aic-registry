---
name: scheduler-task-creator
version: 1.0.0
description: >
  按公司调度组命名规范 v1.0 生成调度任务三件套：调度组名、ClickHouse 调度 SQL（按实例 0/1/2/3 编号顺序执行）、
  含 ${var} 占位的时间变量 JSON 定义（兼容 Java 解析器：{N} unit ago_{pattern} 语法，999 day ago 表月初哨兵值）。
  Use when 创建调度组、配置调度任务、编写调度 SQL、生成时间变量、调度组改名、为新 ETL 任务生成调度配置，
  or when user mentions 调度组、调度任务、调度 SQL、调度变量、时间变量、5min 调度、日级调度、月度结算、
  p95 调度、回填、调度实例、ads_ 出账、scheduler group.
  Do NOT use for ClickHouse 建表（用 clickhouse-table-creator）、查询 SQL 编写、
  Airflow/DolphinScheduler DAG 内部代码、非 ClickHouse 引擎调度（MySQL/Spark）、调度平台运维操作、
  已有调度任务的 ALTER 与下线。
tags: [scheduler, clickhouse, etl, naming]
env-required: false
---

# scheduler-task-creator

交互式引导生成符合公司调度组命名规范 v1.0 的**调度任务三件套**：

1. **调度组名** — `{layer}_{domain}_{theme}_{cycle}`
2. **实例 SQL** — ClickHouse 调度 SQL，按实例编号 `0 / 1 / 2 / 3` 顺序输出，含 `${var}` 占位符
3. **变量 JSON** — 兼容 Java 解析器的时间变量定义（`{N} unit ago_{pattern}`）

**核心约束：**
1. 命名要素不明确时必须向用户提供候选项确认，禁止猜测补全。
2. `layer` / `domain` 取值与 ClickHouse 建表规范完全对齐，**禁止双轨命名**（详见 [命名规范](references/naming-spec.md)）。
3. 一个调度组**只允许一个频率**（cycle）；频率不同必须拆为不同组。
4. 同一组内多个**实例顺序执行**，按 `0 / 1 / 2 / 3` 编号；实例间可有强依赖。
5. 变量 DSL 严格遵循 Java 解析器约定，**禁止自创语法**（详见 [变量语法](references/variable-syntax.md)）。
6. 变量替换是**简单字符串替换**（`${key}` → 值），因此字符串字段必须用 `string` 类型让解析器自动加单引号。

---

## 使用场景

**适用：**
- 新建调度任务（调度组 + SQL + 变量定义）
- 已有调度组新增实例
- 为已建好的 ClickHouse 表配置周期调度
- 月度 / 日级 / 5 分钟级 ETL 任务编写

**不适用：**
- ClickHouse 建表（→ `clickhouse-table-creator`）
- 非 CK 引擎的调度任务
- 临时手工 SQL（不进调度系统）
- 调度平台运维（监控 / 重跑 / 告警配置）

---

## 交互流程

按以下 8 步顺序推进，**每步收集到信息后再进入下一步**。若用户一次性提供了足够信息，跳过对应步骤。

### Step 1 — 确认调度组命名要素

调度组命名格式：`{layer}_{domain}_{theme}_{cycle}`

**Step 1a — layer（目标数据层）**

| 选项 | layer | 说明 |
|------|-------|------|
| A | `ods` | 接入层 |
| B | `dwd` | 明细层 |
| C | `dim` | 维度层 |
| D | `dws` | 汇总层 |
| E | `ads` | 应用层 |
| F | `dmp` | 集市层 |
| G | `tmp` | 临时层（不建议进入正式调度） |

**Step 1b — domain（业务线 + 子域）**

格式 `{iaas|paas}_{2~4 位英文}`，常用值见 [命名规范 §3](references/naming-spec.md)。
若用户输入中文（如"带宽"），推荐对应英文（`iaas_bw`）并确认。

**Step 1c — theme（业务主题）**

2~6 位英文，描述实体或处理对象。常用：`sample` / `billing` / `settle` / `penalty` / `sla` / `report` / `dev` / `access`。

**Step 1d — cycle（调度频率）**

| cycle | 含义 | 推荐适用层 |
|-------|------|------------|
| `5min` | 每 5 分钟 | ods / dwd |
| `1d` | 日级（T+1） | dwd / dim / dws / ads |
| `1w` | 周级 | dws / ads |
| `1mo` | 月级 | dws / ads |

⚠️ **不要把建表周期（`df`/`di`/`rt`/`td`）和调度周期（`5min`/`1d`/`1w`/`1mo`）混淆**，详见 [命名规范 §5](references/naming-spec.md)。

**Step 1e — 展示组名让用户确认**

> 调度组名：`dws_iaas_bw_sample_1d` — 是否确认？

---

### Step 2 — 实例规划

> 该调度组下计划包含几个实例？请列出每个实例的目标表（必须已建好）。

收集示例：

```
实例 0 → 写入 ads_data.ads_lab_95         （月初至昨日 P95 计算）
实例 1 → 写入 ads_data.ads_lab_billing    （月度账单生成）
```

**约束：**
- 实例编号从 `0` 开始递增。
- 实例间为**顺序执行**关系；如无强依赖，应评估是否拆为多个调度组。
- 同一组内所有实例的 `layer / domain / theme / cycle` 必须一致。
- 若某实例目标表尚未建好，**先去用 `clickhouse-table-creator` 建表**，不要在本流程内编造表名。

---

### Step 3 — 逐实例 SQL 编写

对每个实例依次执行 Step 3a~3d：

#### Step 3a — 确认目标表

询问目标表 `db.table`，并要求用户确认表已建好。

#### Step 3b — 确认时间窗口语义

> 本实例处理的数据时间窗口是什么？

常见模式（详见 [SQL 模板](references/sql-patterns.md)）：

| 模式 | 时间窗口语义 | 典型变量 |
|------|--------------|----------|
| 昨日全量 | `[yesterday 00:00:00, yesterday 23:59:59]` | `time_start`, `time_end` |
| 月初至昨日（滚动 P95） | `[本月 1 号 00:00:00, yesterday 23:59:59]` | `time_start`(999 day ago), `time_end` |
| 近 7 日滚动 | `[T-7 00:00:00, yesterday 23:59:59]` | `time_start`(7 day ago), `time_end` |
| 近 30 日滚动 | `[T-30 00:00:00, yesterday 23:59:59]` | `time_start`(30 day ago), `time_end` |
| 上月整月 | `[上月 1 号, 上月最后一天]` | 通常用 1 个 `1 month ago` 推算 |

#### Step 3c — 生成 SQL 骨架

按 ClickHouse 方言生成 `INSERT INTO {target_table} ... SELECT ... WHERE tm >= '${var_start}' AND tm < '${var_end}'`，所有时间窗口字面量用 `${var}` 占位。详见 [SQL 模板](references/sql-patterns.md)。

#### Step 3d — 幂等保护（可选）

> 是否需要幂等（防止重跑产生重复数据）？

- **默认关闭**：CK 的 `ALTER TABLE DELETE` 是异步重型操作，性能差。
- **用户明确要求时**：在实例 SQL 前加一条 `ALTER TABLE {target} DELETE WHERE ds = '${ds}';`，并提示风险。

---

### Step 4 — 变量抽取

扫描所有实例 SQL，收集所有 `${var}` 出现的变量名（去重）。展示给用户确认。

> 检测到以下变量需要定义：`time_start`, `time_end`, `ds`

---

### Step 5 — 变量定义生成

为每个变量生成符合 Java 解析器约定的表达式，格式：

```
{N} {unit} ago_{pattern}
```

| 类别 | 示例值 | 渲染结果 |
|------|--------|----------|
| 月初哨兵 | `999 day ago_yyyy-MM-dd 00:00:00` | 当月 1 号 00:00:00（详见 [变量语法](references/variable-syntax.md)） |
| 昨日开始 | `1 day ago_yyyy-MM-dd 00:00:00` | 昨日 00:00:00 |
| 昨日结束 | `1 day ago_yyyy-MM-dd 23:59:59` | 昨日 23:59:59 |
| 分区日期 | `1 day ago_yyyyMMdd` | 昨日 yyyyMMdd |
| 字面量字符串 | `aliyun,tencent_string` | `'aliyun','tencent'` |
| 字面量数字 | `100,200_digit` | `100,200` |

⚠️ **注意：**
- 替换是**简单字符串替换**：`${var}` → 值。
- 当 `${var}` 出现在 `WHERE col = ${var}` 等位置时，必须用 `string` 类型自动加单引号；纯数值场景才用 `digit`。
- `unit` 仅限：`minute` / `hour` / `day` / `week` / `month` / `year` / `string` / `digit`。
- `999 day ago` 是**月初哨兵值**（约定俗成），其他数字按 `time.plusDays(-N)` 计算。

---

### Step 6 — Mock 渲染验证

用**当前系统时间**替换所有变量，展示**渲染后**的完整 SQL 给用户人工核对：

> 当前时间：2026-05-21 10:30:00
> 变量渲染：
>   `${time_start}` → `2026-05-01 00:00:00`（999 day ago，月初哨兵）
>   `${time_end}`   → `2026-05-20 23:59:59`（1 day ago，昨日 23:59:59）
>
> 渲染后 SQL（仅供核对，请确认时间窗口是否符合预期）：
> ```sql
> ...WHERE tm >= '2026-05-01 00:00:00' AND tm < '2026-05-20 23:59:59'...
> ```

**用户必须确认渲染结果符合预期**才进入 Step 7。

---

### Step 7 — 合规校验

| 校验项 | 规则 | 报错提示 |
|--------|------|----------|
| 调度组名段数 | 必须 4 段 | "调度组名必须包含 layer / domain / theme / cycle" |
| 大小写 | 全 `lower_snake_case` | "命名禁止大写、连字符、空格" |
| layer 合法 | ods/dwd/dim/dws/ads/dmp/tmp | "layer 取值非法" |
| domain 合法 | `iaas_*` 或 `paas_*` | "domain 必须以 iaas_ 或 paas_ 起首" |
| cycle 合法 | 5min/1d/1w/1mo | "cycle 仅支持 5min/1d/1w/1mo" |
| 频率纯净 | 同组所有实例同频 | "调度组内不允许混合频率，请拆组" |
| 实例编号 | 从 0 起连续递增 | "实例编号必须从 0 起连续" |
| 变量 DSL | unit + pattern 合法 | "变量 `{name}` 不符合 `{N} unit ago_{pattern}` 语法" |
| 字符串变量加引号 | string 类型变量替换位无外引号 | "`${var}` 用于 SQL 字符串字段时必须用 string 类型" |

---

### Step 8 — 输出三件套

按以下格式输出：

```
✅ 命名 + 变量 + SQL 校验通过

📋 调度组：dws_iaas_bw_sample_1d

📝 实例 SQL（按编号顺序执行）：

  ── 实例 0 ──
  INSERT INTO ads_data.ads_lab_95
  WITH ... WHERE tm >= '${time_start}' AND tm < '${time_end}' ...

  ── 实例 1 ──
  ...

🔧 变量定义（JSON）：
{
  "time_start": "999 day ago_yyyy-MM-dd 00:00:00",
  "time_end":   "1 day ago_yyyy-MM-dd 23:59:59"
}

⚠️ 部署说明：
  ① 在调度系统创建调度组 `dws_iaas_bw_sample_1d`，频率 1d
  ② 配置全局变量定义（上方 JSON）
  ③ 按编号 0 → 1 → 2 顺序添加实例 SQL
  ④ 上线前先用 Mock 渲染结果在 CK 手工执行一次验证
```

---

## 边界情况处理

| 场景 | 处理方式 |
|------|----------|
| 用户已有完整组名 | 直接进入 Step 2 实例规划，跳过命名交互 |
| 用户提供 SQL 但无变量占位 | 主动询问时间窗口意图，建议改用 `${var}` |
| SQL 含非时间变量（如供应商列表） | 用 `string` / `digit` 字面量类型表达 |
| 用户坚持用违规命名 | 说明违规原因 + 提供合规替代，不输出违规配置 |
| 一组内仅 1 个实例 | 允许，但提示是否能与其他同频同主题任务合并 |
| 跨业务线（IaaS + PaaS） | 拒绝，必须拆组 |
| 实时流（rt） | 当前规范不支持，需要先扩展 |

---

## 与其他 skill 的协作

- **建表先行**：所有目标表必须先用 `clickhouse-table-creator` 建好；本 skill 不生成 DDL。
- **命名同源**：`layer` / `domain` 取值与 `clickhouse-table-creator` 完全一致。

---

## 参考文档

- [调度组命名规范](references/naming-spec.md) — `{layer}_{domain}_{theme}_{cycle}` 完整规则、domain 取值表、反例
- [变量 DSL 语法](references/variable-syntax.md) — Java 解析器对照规则、unit / pattern 取值、999 day ago 哨兵值
- [SQL 模板](references/sql-patterns.md) — 常见调度 SQL 骨架（昨日全量、月度 P95、滚动窗口、月度结算）
- [完整示例](references/examples.md) — 端到端示例（含 ads_lab_95 月度 P95 案例）
