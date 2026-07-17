---
name: clickhouse-table-creator
version: 1.1.2
description: >
  交互式引导生成符合公司 ClickHouse 命名规范（v2.0）的建表 DDL 语句，涵盖本地表、分布式表、视图、物化视图、字典表、Kafka 引擎表等对象类型。
  Use when 创建 ClickHouse 表、生成建表 DDL、新建 ClickHouse 数据表、建 ck 表，
  or when user mentions ClickHouse 建表, DDL 生成, ck 建表, 本地表, 分布式表, ReplicatedMergeTree, Distributed 表, ods/dwd/dim/dws/ads 建表, 带宽计费建表, 设备/采样/计费/扣罚/SLA 表.
  Do NOT use for 查询 SQL 编写、ClickHouse 性能调优、MySQL/PostgreSQL 建表、已有表的 ALTER 操作。
tags: [clickhouse, ddl, database, bigdata]
env-required: false
---

# clickhouse-table-creator

交互式引导用户按照公司 ClickHouse 命名规范 v2.0，生成合规的建表 DDL 语句。

**核心约束：**
1. 命名要素不明确时，必须向用户提供候选项确认，禁止自行猜测补全。
2. 当建表场景属于**带宽计费业务领域**（设备 / 采样 / 计费 / 扣罚 / SLA 监控）时，字段命名**必须优先复用** [字段字典](references/field-dictionary.md)；字典中已定义的字段（含「是否已有 ❌」的规划字段）禁止用同义新名替代。字典外字段方可新增。

---

## 使用场景

**适用：**
- 在 ods / dwd / dim / dws / ads / dmp / tmp 层新建 ClickHouse 表
- 需要同时生成本地表（`_local`）和分布式表（`_dis`）
- 创建视图、物化视图、Kafka 引擎表、字典表

**不适用：**
- 修改已有表结构（ALTER TABLE）
- 编写查询 SQL 或数据分析逻辑
- 非 ClickHouse 数据库的建表

---

## 交互流程

按以下 9 步顺序推进，**每步收集到信息后再进入下一步**。若用户一次性提供了足够信息，跳过对应步骤。

### Step 1 — 确认目标层（数据库）

若用户未明确指定，展示选项：

> 请问您要在哪一层创建表？

| 选项 | 数据库 | 说明 |
|------|--------|------|
| A | `ods` | 接入层，原始贴源数据 |
| B | `dwd` | 明细层，清洗后标准明细 |
| C | `dim` | 维度层，全域公共维度 |
| D | `dws` | 汇总层，指标宽表 |
| E | `ads` | 应用层，报表/BI直连 |
| F | `dmp` | 集市层，主题集市 |
| G | `tmp` | 临时层，开发调试用 |

**规则：** 禁止自定义数据库名（如 `ods_crm`），违规时拒绝并引导至正确选项。

---

### Step 2 — 确认业务域（domain）

业务域为 2~4 位英文缩写。若用户未明确提供，展示常用候选：

> 请确认业务域缩写（也可输入自定义值）：

| 缩写 | 业务含义 | 缩写 | 业务含义 |
|------|----------|------|----------|
| `crm` | 客户关系管理 | `prd` | 商品域 |
| `ord` | 订单域 | `mkt` | 营销域 |
| `usr` | 用户域 | `risk` | 风控域 |
| `fin` | 财务域 | `ops` | 运营域 |
| `log` | 日志域 | | |

若用户输入中文（如"订单"），推荐对应英文缩写并确认：
> 您描述的是"订单"相关业务，推荐使用 `ord`，是否确认？

---

### Step 3 — 确认实体名（entity）

> 请输入业务实体名（英文名词），例如：`order` / `customer` / `sku` / `payment`

若用户输入中文，建议对应英文并确认。

---

### Step 4 — 确认粒度/指标词（grain_or_metric）

根据所选层级动态展示候选词：

**dwd 层（粒度词）：** `detail` / `info` / `record` / `event` / 自定义

**dws / ads 层（指标词）：** `gmv` / `active_cnt` / `pv_uv` / `retention` / `roi` / 自定义

**dim 层（类型词）：** `full`（全量）/ `zip`（拉链 SCD-2）/ `snapshot`（周期快照）

**ods 层：** 可省略此字段，或输入简短描述词。

---

### Step 5 — 确认数据周期（cycle）

> 请选择数据周期后缀：

| 后缀 | 含义 | 适用层 |
|------|------|--------|
| `df` | 每日全量快照 | ods / dim |
| `di` | 每日增量 | ods / dwd |
| `1d` | 日粒度汇总 | dws / ads |
| `7d` | 近7日滚动 | dws |
| `30d` | 近30日滚动 | dws |
| `td` | 历史累积 | dws / ads |
| `rt` | 实时流 | ods / dwd |
| `his` | 历史全量归档 | ods / dwd |

**规则：** 若周期与层级不匹配（如 dim 层选 `1d`），给出警告并建议合规周期。

---

### Step 6 — 确认表类型

> 请选择要创建的对象类型：

| 选项 | 类型 | 说明 |
|------|------|------|
| A | 本地表 + 分布式表（推荐） | 同时生成 `_local` 和 `_dis` |
| B | 仅本地表 | 生成 `_local` |
| C | 仅分布式表 | 生成 `_dis` |
| D | 层间抽取视图 | `vw_{src}_to_{tgt}_{domain}_{entity}_{cycle}` |
| E | 业务语义视图 | `vw_{layer}_{domain}_{entity}_{desc}` |
| F | 物化视图 | `{table_base}_mv_local` |
| G | Kafka 引擎表（仅引擎表） | `ods_{domain}_{entity}_kafka`（仅限 ods 库） |
| H | 字典表 | `dict_{domain}_{entity}` |
| I | 临时表 | `tmp_{dev}_{desc}_{yyyymmdd}` |
| **J** | **Kafka 完整接入链路（推荐）** | **一次性生成 4 个对象，见下方说明** |

#### 选项 J — Kafka 完整接入链路

实际接入 Kafka 数据时，通常需要同时创建以下 4 个对象（缺一不可）：

```
① ods.{domain}_{entity}_kafka          Kafka 引擎表（消费原始消息）
② ods.{domain}_{entity}_rt_local       本地存储表（ReplicatedMergeTree）
③ ods.{domain}_{entity}_rt_dis         分布式表（Distributed）
④ ods.{domain}_{entity}_rt_mv_local    物化视图（Kafka → 本地表的写入桥梁）
```

**选择 J 后的额外交互：**

> 请提供 Kafka 连接信息（用于生成 Kafka 引擎表）：
> 1. **Broker 地址**（如 `kafka-host:9092`）：
> 2. **Topic 名称**：
> 3. **Consumer Group 名称**（建议格式 `ck_{domain}_{entity}`）：
> 4. **消息格式**（默认 `JSONEachRow`，或选 `Avro` / `CSV`）：

字段信息只需填写一次，4 个对象共用同一套字段定义。物化视图的 SELECT 字段由 Skill 自动从字段列表生成，用户可在输出后手动调整转换逻辑。

**Step 7 展示对象清单（选项 J 示例）：**

> 将创建以下 4 个对象：
> - `ods.ord_order_kafka`（Kafka 引擎表）
> - `ods.ods_ord_order_rt_local`（本地表）
> - `ods.ods_ord_order_rt_dis`（分布式表）
> - `ods.ods_ord_order_rt_mv_local`（物化视图）

---

### Step 7 — 展示表名 → 用户确认

在生成 DDL 前，先展示完整表名：

> 根据您的选择，将创建以下表：
> - **本地表**：`dwd.dwd_ord_order_detail_di_local`
> - **分布式表**：`dwd.dwd_ord_order_detail_di_dis`
>
> 是否确认？还是需要修改某个部分？

---

### Step 8 — 收集字段信息

#### Step 8a — 判断是否属于「带宽计费业务领域」

询问或根据上下文判断：本表是否承载 **设备 / 采样 / 计费 / 扣罚 / SLA 监控** 的数据？

- **是** → 启用 [字段字典](references/field-dictionary.md) 强约束，进入 Step 8b。
- **否** → 跳过字典匹配，直接进入 Step 8c。

> 字段字典只针对带宽计费业务，订单 / 用户 / 商品等其他业务域不适用。

#### Step 8b — 字段字典匹配（仅带宽计费领域）

支持两种输入方式：
- **方式 A**：用户粘贴字段列表（JSON / CSV / 文字描述）
- **方式 B**：逐一询问字段名、类型、注释

对每个用户输入的字段执行：

1. **匹配字典**：按英文名直接匹配；按中文名/语义关键词查 [字段字典](references/field-dictionary.md) 的「中文 → 字典字段映射」。
2. **命中**：直接采用字典中的 `字段名 + ClickHouse 类型 + 中文注释`，提示用户：
   > ✅ 已使用规范字段 `device_id Int64`（设备ID）
3. **未命中**：提示
   > ⚠️ 字段「{用户输入}」未在带宽计费字段字典中找到对应项。
   > 是否：
   > - (1) 您指的是字典中的某个字段？（列出语义最接近的 2~3 个候选）
   > - (2) 这是新字段，确认新增（请提供 字段名/类型/注释）

4. **`bbw` 二义性强校验**：当用户字段中出现「保底带宽」「计费带宽」「合同带宽」等模糊语义时：
   - 若本表归属**设备/资源**（type/device/resource 等语义） → 强制使用 `commit_bw`
   - 若本表归属**账单**（bill/invoice/settle 等语义） → 使用 `bbw`
   - 不确定则向用户确认表归属

5. **类型已是 ClickHouse 类型**：字典中类型可直接使用，不需要再做映射（如 `Int64` / `LowCardinality(String)` / `Decimal(18,2)`）。

#### Step 8c — 系统字段自动附加

根据目标层自动建议系统标准字段（见下表），询问用户是否全部保留：

| 层级 | 自动附加的系统字段 |
|------|-------------------|
| ods / dwd | `ds String`（分区日期）、`ctime DateTime`、`utime DateTime`、`etl_batch_id String`、`biz_date Date`、`is_valid UInt8` |
| dim | `ds String`、`ctime DateTime`、`utime DateTime`、`start_date Date`、`end_date Date`（zip 类型额外加） |
| dws / ads | `ds String`、`ctime DateTime`、`utime DateTime`、`stat_date Date` |

> 说明：原 `etl_insert_time` 已替换为字段字典统一的 `ctime`/`utime`；`etl_batch_id` 保留用于 ETL 批次追踪。

若用户输入中文字段名，建议英文对应名并确认，COMMENT 保留中文描述。

#### Step 8d — 字典外新增字段的命名校验

对未命中字典的新增字段，强制校验：

1. **命名**：lower_snake_case，禁止大写/连字符/空格。
2. **单位明确**：带宽必须明示 bps、流量必须明示 Bytes、金额必须明示元、时长须明示 minute/second（可在 COMMENT 中说明）。
3. **类型偏好**：低基数枚举优先 `LowCardinality(String)`；ID 类型优先 `Int64`；金额优先 `Decimal(18,2)` 或 `Decimal(18,6)`。
4. **不得与字典字段语义重复**：如已有 `is_offline`，禁止再造 `offline_flag`/`offline_status`。

---

### Step 9 — 生成完整 DDL，输出

按以下格式输出（详细 DDL 模板见 [DDL 模板参考](references/ddl-templates.md)）：

```
✅ 命名校验通过

📋 生成对象清单：
  - 本地表：{db}.{table_name}_local
  - 分布式表：{db}.{table_name}_dis

📝 DDL 语句：
  [本地表 DDL]
  [分布式表 DDL]

⚠️ 执行说明：
  ① 在每个 shard 节点执行本地表 DDL
  ② 在任意节点执行分布式表 DDL
  ③ 应用层只允许读写 _dis 分布式表，禁止直接操作 _local 表
```

---

## tmp 临时表特殊处理

临时表命名格式：`tmp_{dev}_{desc}_{yyyymmdd}`，额外收集：
1. **责任人标识**（工号如 `u10023` 或姓名拼音如 `zhangsan`）
2. **用途描述**（简短英文，如 `order_test`）
3. **日期**（默认今天，或手动输入）

**注意：** 临时表不创建分布式表，不允许建视图。

---

## 命名合规校验

每个环节执行以下校验，违规时拒绝并提示：

| 校验项 | 规则 | 报错提示 |
|--------|------|----------|
| 数据库名 | 必须为 7 个固定库之一 | "不允许自定义数据库名，请从固定列表中选择" |
| 命名大小写 | 全部小写，禁止大写/连字符/空格 | "命名必须使用 lower_snake_case 格式" |
| 业务域长度 | 2~4 位英文 | "业务域缩写需为 2~4 位英文字母" |
| 分布式后缀 | `_local` 或 `_dis` 必须显式声明 | "本地表和分布式表必须有明确的后缀标识" |
| 视图前缀 | 必须以 `vw_` 开头 | "视图名必须以 vw_ 开头" |
| 字典表前缀 | 必须以 `dict_` 开头 | "字典表名必须以 dict_ 开头" |
| 临时表日期 | 必须有 `yyyymmdd` 日期后缀 | "临时表必须包含日期后缀，格式 yyyyMMdd" |
| 周期与层级匹配 | dim 层不应使用 `1d` 等 | "当前层级不推荐使用该周期后缀，建议使用 {推荐值}" |
| 字段字典优先 | 带宽计费领域字段必须复用 [字段字典](references/field-dictionary.md) | "字段「{name}」与字典中 `{dict_name}` 语义一致，请使用字典字段名" |
| `bbw` 二义性 | 设备/资源表用 `commit_bw`，账单表用 `bbw` | "本表归属为 {表类型}，请使用 `{commit_bw\|bbw}`" |

---

## 边界情况处理

| 场景 | 处理方式 |
|------|----------|
| 用户提供了完整合规的表名 | 直接进入字段收集阶段，跳过命名交互 |
| 用户提供了部分信息 | 仅对缺失/不确定的部分发起确认 |
| 用户坚持使用违规命名 | 说明违规原因，提供合规替代方案，不生成违规 DDL |
| 用户要求批量建表 | 对每张表独立走一遍确认流程，或要求用户提供批量配置 JSON |

---

## 参考文档

- [DDL 模板参考](references/ddl-templates.md) — 各类型完整 DDL 模板（本地表、分布式表、视图、Kafka、字典表）
- [带宽计费字段字典](references/field-dictionary.md) — 带宽计费业务领域字段规范（设备/采样/计费/扣罚/SLA），字典内字段必须优先复用
