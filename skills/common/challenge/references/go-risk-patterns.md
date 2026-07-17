# Go 高频风险模式库

Go 是 aic 主要语言，以下模式作为首要参考。

---

## OOM / 内存泄漏

### 无界集合增长

```go
// ❌ 危险：循环中 append 无上限
func processAll(items []Item) []Result {
    var result []Result
    for _, item := range items {
        result = append(result, process(item))  // 无上限增长
    }
    return result
}
```

**触发条件：** items 来自外部输入或数据库查询，大流量下持续增长  
**修复方向：** 添加上限检查，或改为流式处理

### goroutine 泄漏

```go
// ❌ 危险：goroutine 无明确退出条件
func startWorker(ch <-chan Job) {
    go func() {
        for job := range ch {  // ch 永不关闭时，goroutine 永不退出
            process(job)
        }
    }()
}
```

**触发条件：** ch 永不关闭，或调用方忘记关闭 channel  
**修复方向：** 传入 context，使用 `select { case <-ctx.Done(): return }`

### defer 在循环内

```go
// ❌ 危险：defer 不会在每次迭代时执行，循环结束才统一执行
for _, path := range paths {
    f, _ := os.Open(path)
    defer f.Close()  // 所有文件在循环结束前都不会关闭
}
```

**触发条件：** 循环次数多时，文件描述符耗尽  
**修复方向：** 将循环体提取为函数，或改用 `f.Close()` 显式关闭

### time.After 在循环内

```go
// ❌ 危险：每次迭代创建新 Timer，旧 Timer 在触发前不会被 GC
for {
    select {
    case <-time.After(5 * time.Second):  // 每次迭代泄漏一个 Timer
        doWork()
    }
}
```

**触发条件：** 长期运行，Timer 数量线性增长  
**修复方向：** 在循环外创建 `ticker := time.NewTicker(5 * time.Second)`，循环结束后 `ticker.Stop()`

### 缓存无驱逐

```go
// ❌ 危险：map 只写不删，无 TTL/LRU
var cache = make(map[string][]byte)

func get(key string) []byte {
    if v, ok := cache[key]; ok {
        return v
    }
    v := fetch(key)
    cache[key] = v  // 永不删除
    return v
}
```

**触发条件：** key 空间无限（如用户 ID），运行时间越长内存越高

---

## 崩溃 / Panic

### 空指针解引用

```go
// ❌ 危险：链式调用前无 nil 检查
func getCity(u *User) string {
    return u.Address.City  // u 或 u.Address 为 nil 时 panic
}
```

**修复方向：** 在每一层解引用前检查 nil

### 无保护类型断言

```go
// ❌ 危险：类型不匹配直接 panic
func process(v interface{}) string {
    return v.(string)  // v 不是 string 时 panic
}

// ✅ 安全
s, ok := v.(string)
if !ok {
    return ""
}
```

### goroutine 内无 recover

```go
// ❌ 危险：goroutine 内 panic 会导致整个进程崩溃
go func() {
    riskyOperation()  // 若 panic，进程崩溃
}()

// ✅ 安全
go func() {
    defer func() {
        if r := recover(); r != nil {
            log.Printf("recovered: %v", r)
        }
    }()
    riskyOperation()
}()
```

---

## Go 特有陷阱

### 闭包捕获循环变量

```go
// ❌ 危险：所有 goroutine 共享同一个 i
for i := 0; i < 10; i++ {
    go func() {
        fmt.Println(i)  // 大概率全部打印 10
    }()
}

// ✅ 安全
for i := 0; i < 10; i++ {
    i := i  // 创建新变量
    go func() {
        fmt.Println(i)
    }()
}
```

### interface nil 检查陷阱

```go
// ❌ 危险：(*MyError)(nil) != nil
func getError() error {
    var err *MyError = nil
    return err  // 返回的 error 接口不为 nil！
}

if err := getError(); err != nil {
    // 这里会进入，即使 err 的值是 nil
}
```

### slice 共享底层数组

```go
// ❌ 危险：append 可能静默修改原 slice
func process(data []byte) []byte {
    result := data[:3]
    result = append(result, 0xFF)  // 若 cap(data) > 3，会修改 data[3]
    return result
}
```

**修复方向：** 使用 `data[:3:3]` 限制容量，或 `copy` 创建新 slice

### context 未向下透传

```go
// ❌ 危险：超时/取消信号在中间层丢失
func handleRequest(ctx context.Context) error {
    result, err := db.Query("SELECT ...")  // 未传 ctx，无法被取消
    ...
}

// ✅ 安全
result, err := db.QueryContext(ctx, "SELECT ...")
```

### HTTP Body 无大小限制

```go
// ❌ 危险：攻击者发超大请求导致 OOM
body, err := io.ReadAll(r.Body)

// ✅ 安全
body, err := io.ReadAll(io.LimitReader(r.Body, 10*1024*1024))
```
