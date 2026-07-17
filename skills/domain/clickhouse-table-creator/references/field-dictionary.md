# 带宽计费业务字段字典（ClickHouse 适配版）

> 来源：《带宽计费业务字段数据字典 v1.0》（2026-04-27）+《带宽计费规范文档 v2.0》
> 适用范围：**带宽计费业务领域**的 ClickHouse 表（设备、采样、计费、扣罚、SLA）。
> 规则：
> 1. 表中已列字段（含「是否已有 ❌」）**必须优先复用**，禁止用同义新名（如 `offline_flag` 替代 `is_offline`）。
> 2. 字典外字段方可由用户自定义，命名仍须遵循 lower_snake_case 与单位明确原则。
> 3. `bbw` 一字两义，按表归属选择：
>    - **设备/资源表** → 字段名为 `commit_bw`（保底/买断带宽，合同 BW_commit）
>    - **账单表** → 字段名为 `bbw`（本周期最终计费带宽）
> 4. 数据类型已直接给出 ClickHouse 类型，无需再映射。

---

## 字段总表

| 字段名 | 中文名           | ClickHouse 类型 | 类型归属 | 业务说明 |
|--------|---------------|-----------------|----------|----------|
| `device_id` | 设备ID          | `Int64` | 设备基础 | 设备唯一标识，跨表关联核心外键 |
| `code` | 设备代码          | `String` | 设备基础 | 设备业务编码，唯一，用于外部系统对接 |
| `parent` | 上级设备ID        | `Nullable(Int64)` | 设备基础 | 设备层级归属；顶层设备为 NULL |
| `type` | 节点类型          | `LowCardinality(String)` | 设备基础 | 枚举：专线/汇聚/买断/云主机；**核心字段** |
| `provider` | 供应商代码         | `LowCardinality(String)` | 设备基础 | 设备归属供应商标识 |
| `business_id` | 业务ID          | `Int64` | 设备基础 | 设备所属业务线 |
| `resource_id` | 资源ID          | `Int64` | 设备基础 | 关联资源配置/带宽资源合同 |
| `interface_id` | 网卡ID          | `Int64` | 设备基础 | 网卡唯一标识，采样数据以网卡粒度上报 |
| `commit_bw` | 保底/买断带宽(上行带宽) | `Int64` | 设备基础 | 合同约定最低保障带宽（BW_commit），单位 bps；**仅设备/资源表使用此名** |
| `ufactor` | 带宽系数          | `Decimal(5,4)` | 设备基础 | 实际计费带宽 = 原始带宽 × ufactor；默认 1.0 |
| `ubw` | 上行带宽          | `Int64` | 采样数据 | 设备原始上报上行带宽，单位 bps，未经修正 |
| `dbw` | 下行带宽          | `Int64` | 采样数据 | 设备原始上报下行带宽，单位 bps，未经修正 |
| `aubw` | 调整后上行带宽       | `Int64` | 采样数据 | ubw × ufactor，单位 bps，用于实际计费计算 |
| `adbw` | 调整后下行带宽       | `Int64` | 采样数据 | dbw × ufactor，单位 bps |
| `rbytes` | 接收字节数         | `Int64` | 采样数据 | 采样周期内接收总字节，Bytes |
| `tbytes` | 发送字节数         | `Int64` | 采样数据 | 采样周期内发送总字节，Bytes |
| `stime` | 上报时间          | `DateTime` | 采样数据 | 设备侧采样点上报时间；SLA 扣罚判定核心字段 |
| `atime` | 接收时间          | `DateTime` | 采样数据 | 采集服务实际收到数据的时间 |
| `is_offline` | 是否离线          | `UInt8` | 采样数据 | 1=离线，0=正常；ubw=0 持续超过 1 个采样周期或上报状态 offline |
| `offline_duration` | 离线时长          | `Int32` | 采样数据 | 连续离线累计分钟数；用于 A1/A4 扣罚判定 |
| `time_window` | 时间窗口          | `LowCardinality(String)` | 采样数据 | 枚举：peak / shoulder / idle；由 stime 派生 |
| `period` | 计费周期          | `LowCardinality(String)` | 计费相关 | 枚举：daily / monthly |
| `mode` | 计费方式          | `LowCardinality(String)` | 计费相关 | 枚举：p95_daily / p95_monthly / flat_port / peak_avg / weighted_p95 |
| `price` | 单位价格          | `Decimal(18,6)` | 计费相关 | 合同约定带宽单价，元/Mbps/日 或 元/Mbps/月 |
| `bbw` | 计费带宽          | `Int64` | 计费相关 | 本计费周期最终用于出账的带宽值，bps；**仅账单表使用此名** |
| `bbw_time` | 95计费带宽时间点     | `Nullable(DateTime)` | 计费相关 | 95计费下产生计费带宽值的采样点时间；包端口为 NULL |
| `amount_bbw` | 计费金额          | `Decimal(18,2)` | 计费相关 | 按计费带宽和单价计算的原始应收金额，元 |
| `amount_adjust` | 调整金额          | `Decimal(18,2)` | 计费相关 | B类人工调整层修正金额；扣减为负、补偿为正；默认 0 |
| `amount_total` | 账单金额          | `Decimal(18,2)` | 计费相关 | amount_bbw + amount_adjust，元 |
| `sdate` | 开始日期          | `Date` | 计费相关 | 计费周期开始日期 |
| `edate` | 结束日期          | `Date` | 计费相关 | 计费周期结束日期 |
| `suppress_ratio` | 晚高峰压制比        | `Decimal(5,4)` | 扣罚相关 | V_peak_avg / V_shoulder_avg；< 0.6 连续 2 日触发 A2 |
| `intra_ratio` | 峰谷带宽比         | `Decimal(5,4)` | 扣罚相关 | V_peak_p95 / V_shoulder_p95；> 3.0 且白天95<承诺40% 连续2日触发 A3 |
| `penalty_type` | 扣罚类型          | `LowCardinality(String)` | 扣罚相关 | 枚举：A1/A2/A3/A4/B1/B2/B3/B4/B5 |
| `penalty_trigger_days` | 连续触发天数        | `Int32` | 扣罚相关 | A2/A3 要求连续触发 ≥ 2 天 |
| `k_factor` | 人工调整系数        | `Decimal(5,4)` | 扣罚相关 | B类调整系数，[0,1]；最终结算 = 原金额 × k |
| `notice_date` | 裁撤通知日期        | `Date` | 扣罚相关 | 与 exit_date 差值用于 B5 判定（专线≥15天，汇聚≥7天） |
| `exit_date` | 实际撤资日期        | `Date` | 扣罚相关 | 与 notice_date 结合判定提前通知是否合规 |
| `packet_loss_rate` | 丢包率           | `Decimal(5,2)` | SLA监控 | 晚高峰丢包率%；≥5%/60min 或 ≥10%/30min 触发 B1 |
| `udp_blocked` | UDP是否受限       | `UInt8` | SLA监控 | 1=受限，0=正常；用于 B2 |
| `tcp_fail_rate` | TCP失败率        | `Decimal(5,2)` | SLA监控 | TCP 连接失败率%，用于 B2 |
| `bw_tested` | 压测带宽          | `Int64` | SLA监控 | 买断节点实测带宽，bps；与 commit_bw 对比 < 90% 触发 B3 |
| `offline_device_ratio` | 离线设备占比        | `Decimal(5,4)` | SLA监控 | 机房内离线设备数/总设备数；> 20% 且流量下降 > 10% 触发 B4 |
| `ctime` | 创建时间          | `DateTime` | 通用时间 | 记录写入数据库的时间，由系统自动写入 |
| `utime` | 更新时间          | `DateTime` | 通用时间 | 记录最后一次变更时间，由系统自动维护 |

---

## 中文 → 字典字段映射（用于用户中文输入识别）

| 用户可能输入 | 推荐字段 |
|--------------|----------|
| 设备ID / 设备编号 | `device_id` |
| 设备代码 / 设备编码 | `code` |
| 上级设备 / 父设备 | `parent` |
| 节点类型 / 设备类型 | `type` |
| 供应商 / 厂商 | `provider` |
| 业务 / 业务线 | `business_id` |
| 资源 / 资源合同 | `resource_id` |
| 网卡 / 接口 | `interface_id` |
| 保底带宽 / 买断带宽 / 承诺带宽 / 合同带宽 | `commit_bw`（设备/资源表）|
| 计费带宽 / 出账带宽 / 95带宽 | `bbw`（账单表）|
| 带宽系数 / 修正系数 | `ufactor` |
| 上行带宽 / 上行 | `ubw` |
| 下行带宽 / 下行 | `dbw` |
| 调整后上行 / 修正后上行 | `aubw` |
| 调整后下行 / 修正后下行 | `adbw` |
| 接收字节 / 入流量字节 | `rbytes` |
| 发送字节 / 出流量字节 | `tbytes` |
| 上报时间 / 采样时间 | `stime` |
| 接收时间 / 采集时间 | `atime` |
| 是否离线 / 离线标记 | `is_offline` |
| 离线时长 / 离线分钟 | `offline_duration` |
| 时间窗口 / 时段 / 晚高峰标记 | `time_window` |
| 计费周期 / 周期 | `period` |
| 计费方式 / 计费模式 | `mode` |
| 单价 / 价格 | `price` |
| 计费时间点 / 95时间点 | `bbw_time` |
| 计费金额 / 应收金额 | `amount_bbw` |
| 调整金额 / 修正金额 | `amount_adjust` |
| 账单金额 / 总金额 / 结算金额 | `amount_total` |
| 开始日期 / 起始日期 | `sdate` |
| 结束日期 / 终止日期 | `edate` |
| 压制比 / 晚高峰压制 | `suppress_ratio` |
| 峰谷比 / 峰谷带宽比 | `intra_ratio` |
| 扣罚类型 / 扣罚条款 | `penalty_type` |
| 触发天数 / 连续天数 | `penalty_trigger_days` |
| 调整系数 / k 系数 | `k_factor` |
| 裁撤通知 / 通知日期 | `notice_date` |
| 撤资日期 / 实际下线日期 | `exit_date` |
| 丢包 / 丢包率 | `packet_loss_rate` |
| UDP 限制 / UDP 封锁 | `udp_blocked` |
| TCP 失败 / TCP 失败率 | `tcp_fail_rate` |
| 压测带宽 / 实测带宽 | `bw_tested` |
| 离线占比 / 离线设备比例 | `offline_device_ratio` |
| 创建时间 / 入库时间 | `ctime` |
| 更新时间 / 最后修改时间 | `utime` |

---

## 命名歧义提示

- **`bbw` vs `commit_bw`**：见文件顶部规则 3。建表时根据「类型归属」字段判断归属表类型。
- **`ctime`/`utime` vs `etl_insert_time`**：本字典优先使用 `ctime`/`utime` 作为记录元信息；`etl_batch_id` 仍可保留用于 ETL 批次追踪。
- **未命中字典的字段**：允许新增，但需校验
  1. lower_snake_case 命名
  2. 单位（带宽 bps、流量 Bytes、金额 元、时长 minute/second）需在注释中明确
  3. 非基础类型枚举优先 `LowCardinality(String)`
