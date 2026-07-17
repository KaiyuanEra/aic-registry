# DDL 模板参考

各类型 ClickHouse 对象的完整 DDL 模板。

---

## 本地表（ReplicatedMergeTree）

```sql
-- ① 本地表（在每个 shard 节点执行）
CREATE TABLE {db}.{table_name}_local ON CLUSTER 'ck_cluster'
(
    -- 业务字段
    {field_name}    {type}    COMMENT '{comment}',
    -- ...
    -- 系统标准字段
    ds              String    COMMENT '分区日期 yyyyMMdd',
    etl_insert_time DateTime  DEFAULT now() COMMENT 'ETL写入时间',
    etl_batch_id    String    COMMENT 'ETL批次ID',
    biz_date        Date      COMMENT '业务日期',
    is_valid        UInt8     DEFAULT 1 COMMENT '有效标志 1有效 0无效'
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/{db}/{table_name}',
    '{replica}'
)
PARTITION BY ds
ORDER BY ({sort_keys});
```

**说明：**
- `{shard}` 和 `{replica}` 为 ClickHouse 宏变量，集群自动替换，无需手动填写
- `PARTITION BY ds` 为默认分区键，可根据业务调整
- `ORDER BY` 必须包含查询高频字段，通常为业务主键或时间字段

---

## 分布式表（Distributed）

```sql
-- ② 分布式表（在任意节点执行一次即可）
CREATE TABLE {db}.{table_name}_dis ON CLUSTER 'ck_cluster'
AS {db}.{table_name}_local
ENGINE = Distributed('ck_cluster', '{db}', '{table_name}_local', rand());
```

**说明：**
- `AS {db}.{table_name}_local` 自动继承本地表结构，无需重复声明字段
- `rand()` 为分片键，数据随机分布到各 shard；如有业务分片需求可替换为具体字段

---

## 层间抽取视图

```sql
-- 建在目标层数据库中
CREATE VIEW {tgt_db}.vw_{src_layer}_to_{tgt_layer}_{domain}_{entity}_{cycle} AS
SELECT
    {fields}
FROM {src_db}.{src_table}_dis   -- 读分布式表
WHERE {conditions};
```

**命名示例：** `dwd.vw_ods_to_dwd_ord_order_di`

---

## 业务语义视图

```sql
CREATE VIEW {layer_db}.vw_{layer}_{domain}_{entity}_{desc} AS
SELECT
    {fields}
FROM {layer_db}.{base_table}_dis
WHERE {conditions};
```

**命名示例：** `ads.vw_ads_ord_order_daily_summary`

---

## 物化视图

```sql
-- 物化视图通常配合 Kafka 引擎表使用，将流数据写入本地表
CREATE MATERIALIZED VIEW ods.{table_base}_mv_local
TO ods.{target_table}_local
AS
SELECT
    {fields}
FROM ods.{kafka_table}_kafka;
```

**约束：** 物化视图的 TO 目标必须是已存在的本地表。

---

## Kafka 完整接入链路（四件套）

选项 J 的完整输出模板，4 个对象按以下顺序执行：

```sql
-- ① 本地存储表（每个 shard 节点执行）
CREATE TABLE ods.ods_{domain}_{entity}_rt_local ON CLUSTER 'ck_cluster'
(
    {fields},
    ds              String    COMMENT '分区日期 yyyyMMdd',
    etl_insert_time DateTime  DEFAULT now() COMMENT 'ETL写入时间',
    etl_batch_id    String    COMMENT 'ETL批次ID',
    biz_date        Date      COMMENT '业务日期',
    is_valid        UInt8     DEFAULT 1 COMMENT '有效标志'
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/ods/ods_{domain}_{entity}_rt',
    '{replica}'
)
PARTITION BY ds
ORDER BY ({sort_keys});

-- ② 分布式表（任意节点执行一次）
CREATE TABLE ods.ods_{domain}_{entity}_rt_dis ON CLUSTER 'ck_cluster'
AS ods.ods_{domain}_{entity}_rt_local
ENGINE = Distributed('ck_cluster', 'ods', 'ods_{domain}_{entity}_rt_local', rand());

-- ③ Kafka 引擎表（任意节点执行一次）
CREATE TABLE ods.{domain}_{entity}_kafka ON CLUSTER 'ck_cluster'
(
    {fields}
)
ENGINE = Kafka()
SETTINGS
    kafka_broker_list = '{broker_list}',
    kafka_topic_list  = '{topic}',
    kafka_group_name  = '{consumer_group}',
    kafka_format      = 'JSONEachRow';

-- ④ 物化视图（最后执行，建完即开始消费）
CREATE MATERIALIZED VIEW ods.ods_{domain}_{entity}_rt_mv_local
TO ods.ods_{domain}_{entity}_rt_local
AS
SELECT
    {fields},
    toDate(now())     AS biz_date,
    toString(today()) AS ds,
    ''                AS etl_batch_id,
    1                 AS is_valid
FROM ods.{domain}_{entity}_kafka;
```

**执行顺序说明：**
1. `_local`（每个 shard 节点）
2. `_dis`（任意节点一次）
3. `_kafka`（任意节点一次）
4. `_mv_local`（最后执行，建完即触发消费）

**注意：** 物化视图中系统字段的填充逻辑（`biz_date`、`ds` 等）为默认模板，执行前需确认是否符合业务实际。

---

## Kafka 引擎表（仅引擎表，选项 G）

```sql
-- 仅限 ods 库
CREATE TABLE ods.{domain}_{entity}_kafka ON CLUSTER 'ck_cluster'
(
    {fields}
)
ENGINE = Kafka()
SETTINGS
    kafka_broker_list = '{broker_list}',
    kafka_topic_list  = '{topic}',
    kafka_group_name  = '{consumer_group}',
    kafka_format      = 'JSONEachRow';
```

**典型三件套（Kafka 接入标准模式）：**
1. `ods_{domain}_{entity}_kafka` — Kafka 引擎表（消费原始消息）
2. `ods_{domain}_{entity}_di_local` + `_dis` — 本地表 + 分布式表（存储落地数据）
3. `ods_{domain}_{entity}_di_mv_local` — 物化视图（从 Kafka 表写入本地表）

---

## 字典表

```sql
-- 字典表不需要 ON CLUSTER，通常为单节点小表
CREATE TABLE {db}.dict_{domain}_{entity}
(
    {fields}
)
ENGINE = MergeTree()
ORDER BY ({key_field});
```

**命名示例：** `dim.dict_prd_category`

---

## 临时表

```sql
-- 临时表，仅限 tmp 库，不创建分布式表
CREATE TABLE tmp.tmp_{dev}_{desc}_{yyyymmdd}
(
    {fields}
)
ENGINE = MergeTree()
ORDER BY ({key_field});
```

**命名示例：** `tmp.tmp_zhangsan_order_test_20240115`

---

## 常用字段类型速查

| 场景 | 推荐类型 |
|------|----------|
| 主键 ID（数字） | `UInt64` |
| 主键 ID（字符串） | `String` |
| 金额（精确小数） | `Decimal(18, 4)` |
| 时间戳 | `DateTime` |
| 日期 | `Date` |
| 状态标志 | `UInt8` |
| 枚举值（有限集合） | `LowCardinality(String)` |
| 大文本 | `String` |
| 可空字段 | `Nullable(T)`（谨慎使用，影响性能） |
