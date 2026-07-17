# 端到端示例

完整走一遍 8 步交互流程产出三件套的真实案例。

---

## 示例 1 — 月度 P95 滚动统计（ads_lab_95）

### 业务背景

每日凌晨刷新「本月至昨日」的实验室 P95 带宽统计，写入 `ads_data.ads_lab_95`。
原始采样数据来自 `dwd_data.dwd_global_bandwidth_5m_rich_etl`，按 5 分钟粒度。

### Step 1 — 调度组命名

| 段 | 取值 | 理由 |
|----|------|------|
| layer | `ads` | 应用层报表 |
| domain | `iaas_bw` | IaaS 带宽业务 |
| theme | `lab_p95` | 实验室 P95 主题 |
| cycle | `1d` | 日级刷新（T+1） |

**调度组名：** `ads_iaas_bw_lab_p95_1d`

### Step 2 — 实例规划

仅 1 个实例（实例 0）：写入 `ads_data.ads_lab_95`。

### Step 3 — SQL 编写

**时间窗口：** 月初至昨日 23:59:59（滚动 P95）

```sql
INSERT INTO ads_data.ads_lab_95
WITH lab AS (
    SELECT lab_id, lab_name, channel_id, channel_name,
           area_name, area_id, port_bandwidth
    FROM fn2_center.dim_lab
),
p95 AS (
    SELECT
        channel_id, area_id, lab_id, charge_type,
        floor(arrayReverseSort(groupArray(up))[toInt64(floor(length(groupArray(up))*5/100))]*8/300) AS p95,
        'current_m_95'           AS data_type,
        toDateTime(yesterday())  AS tm
    FROM (
        SELECT
            channel_id, area_id, lab_id,
            sum(upload)            AS up,
            charge_type,
            count(DISTINCT device_id) AS num,
            tm
        FROM dwd_data.dwd_global_bandwidth_5m_rich_etl
        WHERE tm >= '${time3}'
          AND tm <  '${time4}'
        GROUP BY channel_id, lab_id, charge_type, tm, area_id
    )
    GROUP BY channel_id, lab_id, charge_type, area_id
)
SELECT
    channel_id, area_id, lab_id, charge_type,
    p95, data_type, tm,
    lab_name, channel_name, area_name, port_bandwidth,
    -1, '-', now()
FROM p95
JOIN lab
  ON p95.channel_id = lab.channel_id
 AND p95.lab_id     = lab.lab_id
 AND p95.area_id    = lab.area_id;
```

### Step 4 — 变量抽取

`${time3}`, `${time4}`

### Step 5 — 变量定义

```json
{
  "time3": "999 day ago_yyyy-MM-dd 00:00:00",
  "time4": "1 day ago_yyyy-MM-dd 23:59:59"
}
```

### Step 6 — Mock 渲染（假设当前 = 2026-05-21 02:00:00）

| 变量 | 渲染值 |
|------|--------|
| `${time3}` | `2026-05-01 00:00:00`（999 day ago，本月 1 号） |
| `${time4}` | `2026-05-20 23:59:59`（1 day ago，昨日 23:59:59） |

渲染后 `WHERE` 子句：
```sql
WHERE tm >= '2026-05-01 00:00:00'
  AND tm <  '2026-05-20 23:59:59'
```

✅ 时间窗口符合「本月至昨日」预期。

### Step 7 — 校验

| 校验项 | 通过 |
|--------|------|
| 命名 4 段 | ✅ `ads_iaas_bw_lab_p95_1d` |
| layer 合法 | ✅ `ads` |
| domain 合法 | ✅ `iaas_bw` |
| cycle 合法 | ✅ `1d` |
| 变量 DSL | ✅ 两个变量均符合 `{N} unit ago_{pattern}` |
| 时间字面量加引号 | ✅ SQL 中 `'${time3}'` `'${time4}'` 外部带引号 |

### Step 8 — 输出三件套

```
📋 调度组：ads_iaas_bw_lab_p95_1d

📝 实例 SQL（按编号顺序执行）：
  ── 实例 0 ──
  INSERT INTO ads_data.ads_lab_95 ... （见 Step 3）

🔧 变量定义（JSON）：
{
  "time3": "999 day ago_yyyy-MM-dd 00:00:00",
  "time4": "1 day ago_yyyy-MM-dd 23:59:59"
}

⚠️ 部署说明：
  ① 调度系统创建调度组 `ads_iaas_bw_lab_p95_1d`，频率 1d，建议触发时间 02:00
  ② 配置全局变量定义（上方 JSON）
  ③ 添加实例 0：上述 INSERT INTO 语句
  ④ 上线前用 Mock 渲染结果（time3=2026-05-01 00:00:00, time4=2026-05-20 23:59:59）
     在 CK 手工执行验证一次
```

---

## 示例 2 — 多实例顺序执行（带宽采样日级聚合）

### 业务背景

调度组 `dws_iaas_bw_sample_1d`，包含 3 个有依赖关系的实例：

- 实例 0：先汇总 P95
- 实例 1：再汇总峰值/均值
- 实例 2：最后汇总离线统计（依赖前两个实例的结果）

### 三件套输出

**调度组：** `dws_iaas_bw_sample_1d`

**实例 SQL：**

```sql
-- ── 实例 0 ──
INSERT INTO dws_data.dws_bw_sample_p95_1d_local
SELECT channel_id, lab_id,
       quantile(0.95)(upload * 8 / 300) AS p95,
       '${stat_date}' AS stat_date
FROM dwd_data.dwd_global_bandwidth_5m_rich_etl
WHERE tm >= '${time_start}' AND tm < '${time_end}'
GROUP BY channel_id, lab_id;

-- ── 实例 1 ──
INSERT INTO dws_data.dws_bw_sample_peak_avg_1d_local
SELECT channel_id, lab_id,
       max(upload * 8 / 300) AS peak,
       avg(upload * 8 / 300) AS avg_v,
       '${stat_date}' AS stat_date
FROM dwd_data.dwd_global_bandwidth_5m_rich_etl
WHERE tm >= '${time_start}' AND tm < '${time_end}'
GROUP BY channel_id, lab_id;

-- ── 实例 2 ──
INSERT INTO dws_data.dws_bw_sample_offline_stat_1d_local
SELECT a.channel_id, a.lab_id,
       a.p95, b.peak, b.avg_v,
       '${stat_date}' AS stat_date
FROM dws_data.dws_bw_sample_p95_1d_dis     a
JOIN dws_data.dws_bw_sample_peak_avg_1d_dis b
  ON a.channel_id = b.channel_id AND a.lab_id = b.lab_id
WHERE a.stat_date = '${stat_date}'
  AND b.stat_date = '${stat_date}';
```

**变量定义：**
```json
{
  "time_start": "1 day ago_yyyy-MM-dd 00:00:00",
  "time_end":   "1 day ago_yyyy-MM-dd 23:59:59",
  "stat_date":  "1 day ago_yyyy-MM-dd"
}
```

**说明：**
- 实例 2 依赖实例 0、1 的输出，必须严格按 `0 → 1 → 2` 顺序执行。
- 同一组共享一份变量 JSON，三个实例 SQL 共用 `${time_start}` / `${time_end}` / `${stat_date}`。
- 实例 2 读分布式表（`_dis`），写本地表（`_local`），符合公司 CK 读写约定。

---

## 示例 3 — 字符串字面量参数（多供应商分组结算）

### 业务背景

每日按供应商分别结算流量，供应商列表写在变量中便于扩展。

**调度组：** `ads_iaas_bill_settle_1d`

**实例 SQL（实例 0）：**

```sql
INSERT INTO ads_data.ads_provider_settle
SELECT
    provider,
    sum(traffic_gb) AS total_gb,
    sum(amount)     AS total_amount,
    '${biz_date}'   AS biz_date
FROM dwd_data.dwd_provider_bill_di_dis
WHERE tm >= '${time_start}'
  AND tm <  '${time_end}'
  AND provider IN (${providers})
GROUP BY provider;
```

**变量定义：**
```json
{
  "time_start": "1 day ago_yyyy-MM-dd 00:00:00",
  "time_end":   "1 day ago_yyyy-MM-dd 23:59:59",
  "biz_date":   "1 day ago_yyyy-MM-dd",
  "providers":  "aliyun,tencent,huawei_string"
}
```

**渲染后 `IN` 子句：**
```sql
AND provider IN ('aliyun','tencent','huawei')
```

⚠️ 注意 SQL 模板中 `IN (${providers})` **外部不加引号**，由 `string` 类型自动包裹。

---

## 反例集锦

| 反例 | 问题 | 修正 |
|------|------|------|
| `WHERE tm >= ${time_start}` | 时间字面量缺外引号 | `WHERE tm >= '${time_start}'` |
| `IN ('${providers}')` + `string` 类型 | 重复加引号导致语法错误 | `IN (${providers})` |
| `LIMIT '${n}'` + `digit` 类型 | LIMIT 后接字符串会报错 | `LIMIT ${n}` |
| 变量定义 `today_yyyy-MM-dd` | 缺 `{N} unit ago_` 前缀 | `0 day ago_yyyy-MM-dd` |
| 变量定义 `1 days ago_yyyy-MM-dd` | unit 拼写错误（应为单数 `day`） | `1 day ago_yyyy-MM-dd` |
| 用 `998 day ago` 模拟月初 | 不在解析器特殊语义内 | 必须用 `999 day ago` |
| 同组实例频率 5min + 1d 混用 | 调度组规则禁止 | 拆为两个调度组 |
