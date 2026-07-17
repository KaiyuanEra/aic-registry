# 并发问题专项

---

## goroutine 泄漏识别模式

### 模式 1：channel 永不关闭

```go
// ❌ 泄漏：producer 不关闭 ch，consumer goroutine 永远阻塞
func leak() {
    ch := make(chan int)
    go func() {
        for v := range ch {  // ch 永不关闭，goroutine 永不退出
            process(v)
        }
    }()
    // ch 超出作用域，但 goroutine 仍在运行
}
```

**识别特征：** goroutine 函数体中有 `for range ch` 或 `<-ch`，但 ch 的关闭路径不明确

### 模式 2：无 context 的阻塞调用

```go
// ❌ 泄漏：没有超时/取消机制
go func() {
    result := <-longRunningChan  // 若 longRunningChan 永不发送，goroutine 永远阻塞
    process(result)
}()
```

**修复方向：** 使用 `select { case result := <-ch: ... case <-ctx.Done(): return }`

### 模式 3：WaitGroup 计数错误

```go
// ❌ 危险：wg.Add 在 goroutine 内部调用，可能在 wg.Wait 之后才执行
for _, item := range items {
    go func(item Item) {
        wg.Add(1)  // 错误：应在 goroutine 外调用
        defer wg.Done()
        process(item)
    }(item)
}
wg.Wait()

// ✅ 安全
for _, item := range items {
    wg.Add(1)
    go func(item Item) {
        defer wg.Done()
        process(item)
    }(item)
}
```

---

## 竞争条件

### map 并发读写

```go
// ❌ 危险：Go map 不是并发安全的
var cache = make(map[string]string)

func set(k, v string) { cache[k] = v }  // 并发写
func get(k string) string { return cache[k] }  // 并发读

// ✅ 安全：使用 sync.Map 或加锁
var mu sync.RWMutex
var cache = make(map[string]string)

func set(k, v string) {
    mu.Lock()
    defer mu.Unlock()
    cache[k] = v
}
```

**识别特征：** map 变量在多个 goroutine 中读写，且没有 mutex 保护

### 共享变量无锁保护

```go
// ❌ 危险：counter 在多个 goroutine 中并发修改
var counter int

func increment() { counter++ }  // 非原子操作，存在竞争

// ✅ 安全
var counter int64
func increment() { atomic.AddInt64(&counter, 1) }
```

---

## 死锁模式

### 锁顺序不一致

```go
// ❌ 危险：两个 goroutine 以相反顺序获取锁
// goroutine 1: lock(A) → lock(B)
// goroutine 2: lock(B) → lock(A)
// 可能死锁
```

**识别特征：** 同一组锁在不同函数中以不同顺序获取

### channel 死锁

```go
// ❌ 危险：向无缓冲 channel 发送，但没有接收方
ch := make(chan int)
ch <- 1  // 永远阻塞，没有 goroutine 接收

// ❌ 危险：goroutine 互相等待对方的 channel
ch1 := make(chan int)
ch2 := make(chan int)
go func() { ch1 <- <-ch2 }()
go func() { ch2 <- <-ch1 }()
```

---

## sync 包误用

### sync.Mutex 值拷贝

```go
// ❌ 危险：Mutex 被值拷贝后，两个副本独立，失去互斥效果
type Cache struct {
    mu   sync.Mutex
    data map[string]string
}

func process(c Cache) {  // 值传递，mu 被拷贝
    c.mu.Lock()
    defer c.mu.Unlock()
    // 这个锁和原始 Cache 的锁是不同的
}

// ✅ 安全：使用指针接收者
func process(c *Cache) { ... }
```

### sync.Once 内部 panic

```go
// ❌ 危险：Once.Do 内部 panic 后，Once 标记为已执行，后续调用不会重试
var once sync.Once
once.Do(func() {
    if err := initialize(); err != nil {
        panic(err)  // panic 后 once 永远不会再执行
    }
})
```
