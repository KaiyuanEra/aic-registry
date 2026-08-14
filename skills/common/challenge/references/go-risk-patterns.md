# Go Risk Pattern Library

Go is the primary language for aic; the following patterns serve as the primary reference.

---

## OOM / Memory Leak

### Unbounded collection growth

```go
// DANGEROUS: append in loop without limit
func processAll(items []Item) []Result {
    var result []Result
    for _, item := range items {
        result = append(result, process(item))  // unbounded growth
    }
    return result
}
```

**Trigger condition:** items from external input or database query; grows continuously under high traffic
**Fix direction:** add a limit check, or switch to streaming processing

### goroutine leak

```go
// DANGEROUS: goroutine has no clear exit condition
func startWorker(ch <-chan Job) {
    go func() {
        for job := range ch {  // if ch never closes, goroutine never exits
            process(job)
        }
    }()
}
```

**Trigger condition:** ch never closed, or caller forgot to close the channel
**Fix direction:** pass in context; use `select { case <-ctx.Done(): return }`

### defer inside loop

```go
// DANGEROUS: defer does not execute per iteration; all execute at loop end
for _, path := range paths {
    f, _ := os.Open(path)
    defer f.Close()  // no files closed until loop ends
}
```

**Trigger condition:** many iterations cause file descriptor exhaustion
**Fix direction:** extract loop body into a function, or use explicit `f.Close()`

### time.After inside loop

```go
// DANGEROUS: each iteration creates a new Timer; old Timers not GC before firing
for {
    select {
    case <-time.After(5 * time.Second):  // leaks a Timer per iteration
        doWork()
    }
}
```

**Trigger condition:** long-running; Timer count grows linearly
**Fix direction:** create `ticker := time.NewTicker(5 * time.Second)` outside the loop; call `ticker.Stop()` after

### Cache without eviction

```go
// DANGEROUS: map only writes, never deletes; no TTL/LRU
var cache = make(map[string][]byte)

func get(key string) []byte {
    if v, ok := cache[key]; ok {
        return v
    }
    v := fetch(key)
    cache[key] = v  // never deleted
    return v
}
```

**Trigger condition:** key space is unbounded (e.g. user IDs); memory grows over time

---

## Crash / Panic

### Nil pointer dereference

```go
// DANGEROUS: chained call without nil check
func getCity(u *User) string {
    return u.Address.City  // panic if u or u.Address is nil
}
```

**Fix direction:** check nil at each level of dereference

### Unprotected type assertion

```go
// DANGEROUS: type mismatch causes direct panic
func process(v interface{}) string {
    return v.(string)  // panic if v is not string
}

// SAFE
s, ok := v.(string)
if !ok {
    return ""
}
```

### No recover in goroutine

```go
// DANGEROUS: panic in goroutine crashes the entire process
go func() {
    riskyOperation()  // if panic, process crashes
}()

// SAFE
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

## Go-Specific Pitfalls

### Closure capturing loop variable

```go
// DANGEROUS: all goroutines share the same i
for i := 0; i < 10; i++ {
    go func() {
        fmt.Println(i)  // most likely all print 10
    }()
}

// SAFE
for i := 0; i < 10; i++ {
    i := i  // create new variable
    go func() {
        fmt.Println(i)
    }()
}
```

### interface nil check pitfall

```go
// DANGEROUS: (*MyError)(nil) != nil
func getError() error {
    var err *MyError = nil
    return err  // returned error interface is not nil!
}

if err := getError(); err != nil {
    // enters here even though err value is nil
}
```

### slice sharing underlying array

```go
// DANGEROUS: append may silently modify original slice
func process(data []byte) []byte {
    result := data[:3]
    result = append(result, 0xFF)  // if cap(data) > 3, modifies data[3]
    return result
}
```

**Fix direction:** use `data[:3:3]` to limit capacity, or `copy` to create a new slice

### context not propagated

```go
// DANGEROUS: timeout/cancellation signal lost at intermediate layer
func handleRequest(ctx context.Context) error {
    result, err := db.Query("SELECT ...")  // ctx not passed; cannot be cancelled
    ...
}

// SAFE
result, err := db.QueryContext(ctx, "SELECT ...")
```

### HTTP Body without size limit

```go
// DANGEROUS: attacker sends oversized request causing OOM
body, err := io.ReadAll(r.Body)

// SAFE
body, err := io.ReadAll(io.LimitReader(r.Body, 10*1024*1024))
```
