# 变量 DSL 语法

调度任务中的 `${var}` 占位符由后端 Java 解析器（`parseTimeVariable`）按系统时间动态替换。本规范严格对齐解析器实现，**禁止自创语法**。

---

## 1. 表达式格式

```
{amount}{unit} ago_{pattern}
```

下划线 `_` 分隔两段：
- 左段：时间偏移表达式（或字面量内容）
- 右段：格式化 pattern（或类型标签）

**示例：**
```
1 day ago_yyyy-MM-dd 00:00:00       昨日 00:00:00
999 day ago_yyyy-MM-dd 00:00:00     当月 1 号 00:00:00（哨兵值）
30 day ago_yyyy-MM-dd HH:mm:ss      30 天前的此刻
1 hour ago_yyyy-MM-dd HH:00:00      上一小时整点
aliyun,tencent_string                'aliyun','tencent'
100,200,300_digit                    100,200,300
```

---

## 2. unit 取值

### 2.1 时间型 unit

| unit | 行为 | 触发关键字 |
|------|------|------------|
| `minute` | `time.plusMinutes(-amount)` | 表达式包含 `minute` |
| `hour`   | `time.plusHours(-amount)`   | 表达式包含 `hour`   |
| `day`    | `time.plusDays(-amount)`    | 表达式包含 `day`    |
| `week`   | `time.plusWeeks(-amount)`   | 表达式包含 `week`   |
| `month`  | `time.plusMonths(-amount)`  | 表达式包含 `month`  |
| `year`   | `time.plusYears(-amount)`   | 表达式包含 `year`   |

**注意：** `amount` 是表达式中提取出的纯数字（通过正则匹配，外部传入），最终解析器会取负值表示「过去」。

### 2.2 字面量 unit

由 `pattern` 字段为 `string` 或 `digit` 时启用，不做时间计算：

| pattern | 行为 | 输出格式 |
|---------|------|----------|
| `string` | 把左段按 `,` 分割的每个值用单引号包裹 | `'a','b','c'` |
| `digit`  | 把左段按 `,` 分割的每个值原样输出 | `1,2,3` |

---

## 3. 999 day ago 月初哨兵值（特殊语义）

`amount = 999` 是**约定俗成的月初哨兵值**：

```java
if (Math.abs(amount) == 999) {
    if (time.getDayOfMonth() == 1) {
        // 当前是 1 号 → 取上月 1 号 00:00:00
        time1 = time.minusMonths(1).withDayOfMonth(1).withHour(0)...
    } else {
        // 其他日 → 取本月 1 号 00:00:00
        time1 = time.withDayOfMonth(1).withHour(0)...
    }
}
```

**用途：** 月度滚动统计（如月初至昨日的 P95 / 累计金额）。

**示例：**
```
今天 = 2026-05-15
999 day ago_yyyy-MM-dd 00:00:00 → 2026-05-01 00:00:00

今天 = 2026-06-01（月初当天）
999 day ago_yyyy-MM-dd 00:00:00 → 2026-05-01 00:00:00（取上月 1 号）
```

⚠️ **不要用其他数字模拟此语义**；不要扩展为 998 / 997。

---

## 4. pattern 取值

### 4.1 时间格式 pattern

任意合法的 `java.time.format.DateTimeFormatter` pattern：

| pattern | 输出示例 |
|---------|----------|
| `yyyy-MM-dd` | `2026-05-21` |
| `yyyy-MM-dd 00:00:00` | `2026-05-21 00:00:00` |
| `yyyy-MM-dd HH:mm:ss` | `2026-05-21 10:30:00` |
| `yyyyMMdd` | `20260521` |
| `yyyyMM` | `202605` |
| `yyyy` | `2026` |
| `HH:mm:ss` | `10:30:00` |

### 4.2 字面量类型 pattern

| pattern | 含义 | 与 unit 联动 |
|---------|------|--------------|
| `string` | 字符串字面量，自动加单引号 | unit = `nomal` |
| `digit`  | 数字字面量，原样输出 | unit = `nomal` |

---

## 5. 字符串注入注意事项

变量替换是**简单字符串替换**：

```java
sql.replace("${" + key + "}", value);
```

因此：

| SQL 上下文 | 推荐变量类型 | 错误示范 |
|-----------|--------------|----------|
| `WHERE tm >= '${time_start}'` | 时间格式 pattern（外有引号） | ❌ `time_start` 用 `string` 类型会导致重复加引号 |
| `WHERE channel IN (${channels})` | `string`（自动加引号） | ❌ 不要在 SQL 模板里再写 `IN ('${...}')` |
| `LIMIT ${n}` | `digit` | ❌ 用 `string` 会变成 `LIMIT '100'` 报错 |
| `INSERT INTO ${table}` | `string` 但**不要加外引号** | 表名替换不需要引号 |

**通用规则：**
- **时间窗口字面量**（`WHERE tm >= '${var}'`）：用时间 pattern，外部 SQL 自己加引号。
- **字符串集合**（`IN (${var})`）：用 `string`，外部 SQL **不要**加引号。
- **数值字面量**（`LIMIT ${var}` / `WHERE id = ${var}`）：用 `digit`。

---

## 6. 完整对照表

| 变量定义 | 当前时间假设 | 渲染结果 |
|----------|--------------|----------|
| `1 day ago_yyyy-MM-dd 00:00:00` | 2026-05-21 10:30:00 | `2026-05-20 00:00:00` |
| `1 day ago_yyyy-MM-dd 23:59:59` | 2026-05-21 10:30:00 | `2026-05-20 23:59:59` |
| `1 day ago_yyyyMMdd` | 2026-05-21 10:30:00 | `20260520` |
| `999 day ago_yyyy-MM-dd 00:00:00` | 2026-05-21 10:30:00 | `2026-05-01 00:00:00` |
| `999 day ago_yyyy-MM-dd 00:00:00` | 2026-06-01 02:00:00 | `2026-05-01 00:00:00` |
| `1 month ago_yyyyMM` | 2026-05-21 10:30:00 | `202604` |
| `7 day ago_yyyy-MM-dd 00:00:00` | 2026-05-21 10:30:00 | `2026-05-14 00:00:00` |
| `1 hour ago_yyyy-MM-dd HH:00:00` | 2026-05-21 10:30:00 | `2026-05-21 09:00:00` |
| `5 minute ago_yyyy-MM-dd HH:mm:00` | 2026-05-21 10:30:00 | `2026-05-21 10:25:00` |
| `aliyun,tencent_string` | （不依赖时间） | `'aliyun','tencent'` |
| `aliyun_string` | （不依赖时间） | `'aliyun'` |
| `100,200_digit` | （不依赖时间） | `100,200` |

---

## 7. 校验规则

| 校验项 | 规则 | 报错提示 |
|--------|------|----------|
| 表达式段数 | 必须用 `_` 分两段 | "变量 `{name}` 必须为 `<左段>_<pattern>` 格式" |
| amount 为整数 | 左段 `amount` 部分能解析为整数 | "amount 必须为整数" |
| unit 合法 | minute/hour/day/week/month/year 之一 | "unit 取值非法" |
| pattern 合法 | 合法 DateTimeFormatter pattern 或 string/digit | "pattern 不合法" |
| 999 day ago 仅用于月初语义 | 警告：非月初统计场景慎用 999 | "确认 999 day ago 是月初哨兵值用法" |
| 字面量 string 多值 | 用 `,` 分隔，不要混入空格 | "string 多值必须用逗号分隔" |
