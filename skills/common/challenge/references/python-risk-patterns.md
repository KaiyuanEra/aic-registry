# Python Risk Pattern Library

---

## Crash

### KeyError: direct dict indexing

```python
# DANGEROUS: KeyError when key does not exist
user = data["user"]
name = user["name"]

# SAFE: use .get() or try/except
name = data.get("user", {}).get("name", "")
```

### Type error without check

```python
# DANGEROUS: assumes input type; may be None or other type
def process(value):
    return value.strip()  # AttributeError if value is None

# SAFE
def process(value: str | None) -> str:
    if value is None:
        return ""
    return value.strip()
```

---

## Resource Leak

### File/connection not using with

```python
# DANGEROUS: resource not released on exception
f = open("file.txt")
data = f.read()
f.close()  # if read() throws, close does not execute

# SAFE
with open("file.txt") as f:
    data = f.read()
```

### Database connection not returned

```python
# DANGEROUS: connection not returned to pool on exception
conn = pool.get_connection()
result = conn.execute(query)
pool.release(conn)  # if execute throws, connection leaks

# SAFE
with pool.get_connection() as conn:
    result = conn.execute(query)
```

---

## Python-Specific Pitfalls

### Mutable default argument

```python
# DANGEROUS: all calls share the same list
def append_item(item, lst=[]):
    lst.append(item)
    return lst

append_item(1)  # [1]
append_item(2)  # [1, 2]  <- not [2]!

# SAFE
def append_item(item, lst=None):
    if lst is None:
        lst = []
    lst.append(item)
    return lst
```

### Bare except swallowing system exceptions

```python
# DANGEROUS: swallows KeyboardInterrupt, SystemExit
try:
    risky_operation()
except:  # catches everything including system exits
    pass

# SAFE
try:
    risky_operation()
except Exception as e:
    log.error(f"operation failed: {e}")
```

### GIL affecting concurrency assumptions

```python
# MISUNDERSTANDING: thinking threading can parallelize CPU-intensive tasks
import threading

def cpu_intensive():
    # heavy computation
    ...

threads = [threading.Thread(target=cpu_intensive) for _ in range(4)]
# due to GIL, only one thread executes Python bytecode at a time
# CPU-intensive tasks should use multiprocessing or concurrent.futures.ProcessPoolExecutor
```

### Float precision for monetary calculations

```python
# DANGEROUS: float precision issues
price = 0.1 + 0.2
print(price == 0.3)  # False!
print(price)  # 0.30000000000000004

# SAFE: use Decimal
from decimal import Decimal
price = Decimal("0.1") + Decimal("0.2")
print(price == Decimal("0.3"))  # True
```

### Generator closed prematurely

```python
# DANGEROUS: generator closed before iteration completes; subsequent operations may lose data
def process_stream(gen):
    for item in gen:
        if should_stop(item):
            return  # generator not exhausted; cleanup logic may be missed
        process(item)
```

### Thread sharing mutable state

```python
# DANGEROUS: compound operations on list/dict are not atomic
shared_list = []

def append_if_not_exists(item):
    if item not in shared_list:  # check
        shared_list.append(item)  # modify (may be switched between check and modify)

# SAFE: use threading.Lock
lock = threading.Lock()

def append_if_not_exists(item):
    with lock:
        if item not in shared_list:
            shared_list.append(item)
```
