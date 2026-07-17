# 调度 SQL 模板（ClickHouse）

调度任务常见 SQL 骨架。所有时间字面量用 `${var}` 占位，由后端 Java 解析器渲染。

⚠️ **通用约束：**
- 仅 ClickHouse 方言。
- 写入分布式表读、本地表写（应用层只读 `_dis`，写入走 `_local`，由调度系统决定）；本模板默认 `INSERT INTO {target}` 由用户根据规范选择。
- 默认**不做幂等**；若需幂等见模板 5。

---

## 模板 1 — 昨日全量增量入库

**适用：** dwd 层每日增量同步

```sql
INSERT INTO dwd_data.dwd_xxx_di_local
SELECT
    field1, field2, ...,
    toString(toDate(tm))     AS ds,
    now()                    AS ctime,
    now()                    AS utime,
    toDate(tm)               AS biz_date,
    1                        AS is_valid
FROM ods_data.ods_xxx_rt_dis
WHERE tm >= '${time_start}'
  AND tm <  '${time_end}';
```

**变量定义：**
```json
{
  "time_start": "1 day ago_yyyy-MM-dd 00:00:00",
  "time_end":   "1 day ago_yyyy-MM-dd 23:59:59"
}
```

---

## 模板 2 — 月度滚动 P95（月初至昨日）

**适用：** ads 层月度计费 P95 统计，每日刷新

```sql
INSERT INTO ads_data.ads_xxx_p95
WITH base AS (
    SELECT channel_id, lab_id, sum(upload) AS up, tm
    FROM dwd_data.dwd_xxx_5m_dis
    WHERE tm >= '${time_start}'
      AND tm <  '${time_end}'
    GROUP BY channel_id, lab_id, tm
)
SELECT
    channel_id, lab_id,
    floor(arrayReverseSort(groupArray(up))[toInt64(floor(length(groupArray(up))*5/100))]*8/300) AS p95,
    'current_m_95'           AS data_type,
    toDateTime(yesterday())  AS tm
FROM base
GROUP BY channel_id, lab_id;
```

**变量定义：**
```json
{
  "time_start": "999 day ago_yyyy-MM-dd 00:00:00",
  "time_end":   "1 day ago_yyyy-MM-dd 23:59:59"
}
```

> `999 day ago` 是月初哨兵值，详见 [变量语法 §3](variable-syntax.md)。

---

## 模板 3 — 近 N 日滚动汇总

**适用：** dws 层 7d / 30d 滚动指标

```sql
INSERT INTO dws_data.dws_xxx_7d_local
SELECT
    dim1, dim2,
    sum(metric)  AS total,
    avg(metric)  AS avg_v,
    '${stat_date}'   AS stat_date,
    now()        AS ctime
FROM dwd_data.dwd_xxx_di_dis
WHERE tm >= '${time_start}'
  AND tm <  '${time_end}'
GROUP BY dim1, dim2;
```

**变量定义（近 7 日）：**
```json
{
  "time_start": "7 day ago_yyyy-MM-dd 00:00:00",
  "time_end":   "1 day ago_yyyy-MM-dd 23:59:59",
  "stat_date":  "1 day ago_yyyy-MM-dd"
}
```

---

## 模板 4 — 月度结算（上月整月）

**适用：** ads 层月初出账

```sql
INSERT INTO ads_data.ads_xxx_settle
SELECT
    customer_id,
    sum(amount)   AS total_amount,
    '${biz_month}' AS biz_month,
    now()         AS ctime
FROM dwd_data.dwd_xxx_di_dis
WHERE tm >= '${month_start}'
  AND tm <  '${month_end}'
GROUP BY customer_id;
```

**变量定义（每月 1 号执行，结算上月）：**
```json
{
  "month_start": "1 month ago_yyyy-MM-01 00:00:00",
  "month_end":   "1 day ago_yyyy-MM-dd 23:59:59",
  "biz_month":   "1 month ago_yyyyMM"
}
```

> 注：`yyyy-MM-01 00:00:00` 利用 pattern 直接锚定月初，比 `999 day ago` 更直观（适用于"上月 1 号"，非"本月 1 号"）。

---

## 模板 5 — 幂等保护版本（用户明确要求时）

**适用：** 用户明确要求重跑不重复 → 写入前先删该分区

```sql
-- ① 先清理目标分区
ALTER TABLE dws_data.dws_xxx_1d_local
  DELETE WHERE ds = '${ds}';

-- ② 再写入（与模板 1/2/3 相同）
INSERT INTO dws_data.dws_xxx_1d_local
SELECT ... ;
```

**变量补充：**
```json
{
  "ds": "1 day ago_yyyyMMdd"
}
```

⚠️ **风险提示：**
- CK `ALTER TABLE DELETE` 是**异步重型操作**，会触发后台 mutation。
- 大数据量分区删除可能耗时数分钟到数小时。
- 高频调度（5min）不建议使用此模式，应改用 `ReplacingMergeTree` 引擎或 `INSERT INTO ... SELECT` + 业务去重列。

---

## 模板 6 — 字符串字面量参数（供应商过滤）

**适用：** 多供应商分别走不同实例，但 SQL 结构一致

```sql
INSERT INTO ads_data.ads_xxx_by_prv
SELECT
    provider, sum(traffic) AS total
FROM dwd_data.dwd_xxx_di_dis
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
  "providers":  "aliyun,tencent,huawei_string"
}
```

> 渲染后 `${providers}` → `'aliyun','tencent','huawei'`，注意 SQL 模板里 `IN (${providers})` 不要再加单引号。

---

## 通用 SQL 编写检查清单

每条调度 SQL 输出前自检：

- [ ] 时间字面量全部用 `${var}` 占位，没有硬编码日期
- [ ] 字符串变量在 SQL 中**外部不加引号**（由 `string` 类型自动加）
- [ ] 时间格式变量在 SQL 中**外部加引号**（`'${time_start}'`）
- [ ] 数值变量用 `digit` 类型（`LIMIT ${n}`）
- [ ] 写入目标表已建好（`clickhouse-table-creator` 输出过）
- [ ] `WHERE` 条件包含分区裁剪（`tm >= ... AND tm < ...`）
- [ ] 不依赖 ClickHouse 服务器时区（`now()` / `today()` 行为受时区影响，必要时用 `toDateTime('xxx', 'Asia/Shanghai')`）
- [ ] 大查询有 `GROUP BY` 时确保聚合维度合理，避免基数爆炸
