# Python 风险模式库

---

## 崩溃

### KeyError：dict 直接索引

```python
# ❌ 危险：key 不存在时 KeyError
user = data["user"]
name = user["name"]

# ✅ 安全：使用 .get() 或 try/except
name = data.get("user", {}).get("name", "")
```

### 类型错误无检查

```python
# ❌ 危险：假设输入类型，实际可能是 None 或其他类型
def process(value):
    return value.strip()  # value 为 None 时 AttributeError

# ✅ 安全
def process(value: str | None) -> str:
    if value is None:
        return ""
    return value.strip()
```

---

## 资源泄漏

### 文件/连接未用 with

```python
# ❌ 危险：异常时资源不释放
f = open("file.txt")
data = f.read()
f.close()  # 若 read() 抛异常，close 不执行

# ✅ 安全
with open("file.txt") as f:
    data = f.read()
```

### 数据库连接未归还

```python
# ❌ 危险：异常时连接不归还连接池
conn = pool.get_connection()
result = conn.execute(query)
pool.release(conn)  # 若 execute 抛异常，连接泄漏

# ✅ 安全
with pool.get_connection() as conn:
    result = conn.execute(query)
```

---

## Python 特有陷阱

### 可变默认参数

```python
# ❌ 危险：所有调用共享同一个列表
def append_item(item, lst=[]):
    lst.append(item)
    return lst

append_item(1)  # [1]
append_item(2)  # [1, 2]  ← 不是 [2]！

# ✅ 安全
def append_item(item, lst=None):
    if lst is None:
        lst = []
    lst.append(item)
    return lst
```

### 裸 except 吞掉系统异常

```python
# ❌ 危险：吞掉 KeyboardInterrupt、SystemExit
try:
    risky_operation()
except:  # 捕获所有异常，包括系统信号
    pass

# ✅ 安全：明确指定异常类型
try:
    risky_operation()
except (ValueError, IOError) as e:
    logger.error(f"operation failed: {e}")
```

### GIL 影响并发假设

```python
# ❌ 误解：以为 threading 可以并行执行 CPU 密集任务
import threading

def cpu_intensive():
    # 大量计算
    ...

threads = [threading.Thread(target=cpu_intensive) for _ in range(4)]
# 实际上由于 GIL，同一时刻只有一个线程执行 Python 字节码
# CPU 密集任务应使用 multiprocessing 或 concurrent.futures.ProcessPoolExecutor
```

### 浮点精度用于金额计算

```python
# ❌ 危险：浮点精度问题
price = 0.1 + 0.2
print(price == 0.3)  # False！
print(price)  # 0.30000000000000004

# ✅ 安全：使用 Decimal
from decimal import Decimal
price = Decimal("0.1") + Decimal("0.2")
print(price == Decimal("0.3"))  # True
```

### 生成器提前关闭

```python
# ❌ 危险：生成器在迭代完成前被关闭，后续操作可能丢失数据
def process_stream(gen):
    for item in gen:
        if should_stop(item):
            return  # 生成器未耗尽，可能有未处理的清理逻辑
        process(item)
```

### 线程共享可变状态

```python
# ❌ 危险：list/dict 的复合操作不是原子的
shared_list = []

def append_if_not_exists(item):
    if item not in shared_list:  # 检查
        shared_list.append(item)  # 修改（检查和修改之间可能被切换）

# ✅ 安全：使用 threading.Lock
lock = threading.Lock()

def append_if_not_exists(item):
    with lock:
        if item not in shared_list:
            shared_list.append(item)
```
