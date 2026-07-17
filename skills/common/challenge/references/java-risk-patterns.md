# Java / Kotlin 风险模式库

---

## OOM / 内存泄漏

### 大集合未分页加载

```java
// ❌ 危险：一次性加载全表
List<User> users = userRepository.findAll();  // 百万行数据直接进内存

// ✅ 安全：分页查询
Page<User> page = userRepository.findAll(PageRequest.of(0, 100));
```

### ThreadLocal 未清理

```java
// ❌ 危险：线程池复用线程，ThreadLocal 值残留
private static ThreadLocal<UserContext> context = new ThreadLocal<>();

void handleRequest(User user) {
    context.set(new UserContext(user));
    process();
    // 忘记 context.remove()，线程归还线程池后值仍存在
}

// ✅ 安全
try {
    context.set(new UserContext(user));
    process();
} finally {
    context.remove();
}
```

### 字符串拼接在循环内

```java
// ❌ 危险：每次 + 创建新 String 对象
String result = "";
for (String item : items) {
    result += item;  // O(n²) 内存分配
}

// ✅ 安全
StringBuilder sb = new StringBuilder();
for (String item : items) {
    sb.append(item);
}
```

---

## 崩溃

### NPE 链式调用

```java
// ❌ 危险：任意一层为 null 时 NPE
String city = user.getAddress().getCity().toUpperCase();

// ✅ 安全：Optional 链
String city = Optional.ofNullable(user)
    .map(User::getAddress)
    .map(Address::getCity)
    .map(String::toUpperCase)
    .orElse("");
```

### 线程池拒绝策略未配置

```java
// ❌ 危险：默认 AbortPolicy，队列满时抛 RejectedExecutionException
ExecutorService pool = new ThreadPoolExecutor(
    10, 20, 60L, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(100)
    // 未指定 RejectedExecutionHandler
);
```

**触发条件：** 突发流量导致队列满，未捕获的异常可能导致请求丢失

---

## 并发

### HashMap 并发修改

```java
// ❌ 危险：HashMap 不是线程安全的
Map<String, String> cache = new HashMap<>();
// 多线程并发 put 可能导致死循环（Java 7）或数据丢失（Java 8+）

// ✅ 安全
Map<String, String> cache = new ConcurrentHashMap<>();
```

### 双重检查锁无 volatile

```java
// ❌ 危险：instance 可能被观察到部分初始化状态
private static Singleton instance;

public static Singleton getInstance() {
    if (instance == null) {
        synchronized (Singleton.class) {
            if (instance == null) {
                instance = new Singleton();  // 非原子操作
            }
        }
    }
    return instance;
}

// ✅ 安全：添加 volatile
private static volatile Singleton instance;
```

---

## Java 特有陷阱

### 资源未关闭

```java
// ❌ 危险：异常时资源泄漏
InputStream is = new FileInputStream(file);
process(is);
is.close();  // 若 process 抛异常，close 不会执行

// ✅ 安全：try-with-resources
try (InputStream is = new FileInputStream(file)) {
    process(is);
}
```

### equals/hashCode 不一致

```java
// ❌ 危险：只重写 equals，不重写 hashCode
class User {
    @Override
    public boolean equals(Object o) { ... }
    // 未重写 hashCode
}

Set<User> set = new HashSet<>();
set.add(user1);
set.contains(user1);  // 可能返回 false！
```

### Integer 缓存范围

```java
// ❌ 危险：-128~127 范围外，== 比较失效
Integer a = 200;
Integer b = 200;
a == b;  // false！应使用 a.equals(b)
```
