# Java / Kotlin Risk Pattern Library

---

## OOM / Memory Leak

### Large collection loaded without pagination

```java
// DANGEROUS: load entire table at once
List<User> users = userRepository.findAll();  // millions of rows into memory

// SAFE: paginated query
Page<User> page = userRepository.findAll(PageRequest.of(0, 100));
```

### ThreadLocal not cleaned

```java
// DANGEROUS: thread pool reuses threads; ThreadLocal value persists
private static ThreadLocal<UserContext> context = new ThreadLocal<>();

void handleRequest(User user) {
    context.set(new UserContext(user));
    process();
    // forgot context.remove(); value persists after thread returned to pool
}

// SAFE
try {
    context.set(new UserContext(user));
    process();
} finally {
    context.remove();
}
```

### String concatenation inside loop

```java
// DANGEROUS: each + creates a new String object
String result = "";
for (String item : items) {
    result += item;  // O(n^2) memory allocation
}

// SAFE
StringBuilder sb = new StringBuilder();
for (String item : items) {
    sb.append(item);
}
```

---

## Crash

### NPE chained call

```java
// DANGEROUS: NPE if any level is null
String city = user.getAddress().getCity().toUpperCase();

// SAFE: Optional chain
String city = Optional.ofNullable(user)
    .map(User::getAddress)
    .map(Address::getCity)
    .map(String::toUpperCase)
    .orElse("");
```

### Thread pool rejection policy not configured

```java
// DANGEROUS: default AbortPolicy; throws RejectedExecutionException when queue is full
ExecutorService pool = new ThreadPoolExecutor(
    10, 20, 60L, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(100)
    // no RejectedExecutionHandler specified
);
```

**Trigger condition:** burst traffic fills the queue; uncaught exception may cause request loss

---

## Concurrency

### HashMap concurrent modification

```java
// DANGEROUS: HashMap is not thread-safe
Map<String, String> cache = new HashMap<>();
// concurrent put may cause infinite loop (Java 7) or data loss (Java 8+)

// SAFE
Map<String, String> cache = new ConcurrentHashMap<>();
```

### Double-checked locking without volatile

```java
// DANGEROUS: instance may be observed in partially initialized state
private static Singleton instance;

public static Singleton getInstance() {
    if (instance == null) {
        synchronized (Singleton.class) {
            if (instance == null) {
                instance = new Singleton();  // non-atomic operation
            }
        }
    }
    return instance;
}

// SAFE: add volatile
private static volatile Singleton instance;
```

---

## Java-Specific Pitfalls

### Resource not closed

```java
// DANGEROUS: resource leak on exception
InputStream is = new FileInputStream(file);
process(is);
is.close();  // if process throws, close does not execute

// SAFE: try-with-resources
try (InputStream is = new FileInputStream(file)) {
    process(is);
}
```

### equals/hashCode inconsistency

```java
// DANGEROUS: only override equals, not hashCode
class User {
    @Override
    public boolean equals(Object o) { ... }
    // hashCode not overridden
}

Set<User> set = new HashSet<>();
set.add(user1);
set.contains(user1);  // may return false!
```

### Integer cache range

```java
// DANGEROUS: outside -128 to 127, == comparison fails
Integer a = 200;
Integer b = 200;
a == b;  // false! should use a.equals(b)
```
