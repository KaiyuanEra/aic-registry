# Concurrency Issues

---

## goroutine Leak Detection Patterns

### Pattern 1: channel never closed

```go
// LEAK: producer does not close ch; consumer goroutine blocks forever
func leak() {
    ch := make(chan int)
    go func() {
        for v := range ch {  // ch never closed; goroutine never exits
            process(v)
        }
    }()
    // ch goes out of scope, but goroutine still running
}
```

**Detection signature:** goroutine body has `for range ch` or `<-ch`, but ch close path is unclear

### Pattern 2: blocking call without context

```go
// LEAK: no timeout/cancellation mechanism
go func() {
    result := <-longRunningChan  // if longRunningChan never sends, goroutine blocks forever
    process(result)
}()
```

**Fix direction:** use `select { case result := <-ch: ... case <-ctx.Done(): return }`

### Pattern 3: WaitGroup count error

```go
// DANGEROUS: wg.Add called inside goroutine; may execute after wg.Wait
for _, item := range items {
    go func(item Item) {
        wg.Add(1)  // wrong: should be called outside goroutine
        defer wg.Done()
        process(item)
    }(item)
}
wg.Wait()

// SAFE
for _, item := range items {
    wg.Add(1)
    go func(item Item) {
        defer wg.Done()
        process(item)
    }(item)
}
```

---

## Race Conditions

### map concurrent read/write

```go
// DANGEROUS: Go map is not concurrency-safe
var cache = make(map[string]string)

func set(k, v string) { cache[k] = v }  // concurrent write
func get(k string) string { return cache[k] }  // concurrent read

// SAFE: use sync.Map or add a lock
var mu sync.RWMutex
var cache = make(map[string]string)

func set(k, v string) {
    mu.Lock()
    defer mu.Unlock()
    cache[k] = v
}
```

**Detection signature:** map variable read/written in multiple goroutines without mutex protection

### Shared variable without lock protection

```go
// DANGEROUS: counter modified concurrently by multiple goroutines
var counter int

func increment() { counter++ }  // non-atomic; race condition

// SAFE
var counter int64
func increment() { atomic.AddInt64(&counter, 1) }
```

---

## Deadlock Patterns

### Inconsistent lock order

```go
// DANGEROUS: two goroutines acquire locks in opposite order
// goroutine 1: lock(A) -> lock(B)
// goroutine 2: lock(B) -> lock(A)
// potential deadlock
```

**Detection signature:** same set of locks acquired in different order in different functions

### channel deadlock

```go
// DANGEROUS: send to unbuffered channel with no receiver
ch := make(chan int)
ch <- 1  // blocks forever; no goroutine receiving

// DANGEROUS: goroutines waiting on each other channels
ch1 := make(chan int)
ch2 := make(chan int)
go func() { ch1 <- <-ch2 }()
go func() { ch2 <- <-ch1 }()
```

---

## sync Package Misuse

### sync.Mutex value copy

```go
// DANGEROUS: Mutex copied by value; two independent copies lose mutual exclusion
type Cache struct {
    mu   sync.Mutex
    data map[string]string
}

func process(c Cache) {  // pass by value; mu copied
    c.mu.Lock()
    defer c.mu.Unlock()
    // this lock is different from the original Cache lock
}

// SAFE: use pointer receiver
func process(c *Cache) { ... }
```

### sync.Once internal panic

```go
// DANGEROUS: after panic inside Once.Do, Once is marked as executed; subsequent calls will not retry
var once sync.Once
once.Do(func() {
    if err := initialize(); err != nil {
        panic(err)  // after panic, once will never execute again
    }
})
```
