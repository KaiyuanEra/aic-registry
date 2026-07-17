# 安全审查专项

覆盖 OWASP Top 10 中与代码审查直接相关的类别。

---

## SQL 注入

```go
// ❌ 危险：字符串拼接构造 SQL
query := "SELECT * FROM users WHERE name = '" + name + "'"
db.Query(query)

// ✅ 安全：参数化查询
db.Query("SELECT * FROM users WHERE name = ?", name)
```

**触发条件：** name 来自用户输入，传入 `' OR '1'='1` 可绕过认证  
**检查点：** 所有 SQL 构造处，特别是 `fmt.Sprintf` + SQL 关键字组合

---

## 命令注入

```go
// ❌ 危险：用户输入传入 exec
cmd := exec.Command("sh", "-c", "ls " + userInput)

// ✅ 安全：参数分离，不经过 shell 解析
cmd := exec.Command("ls", userInput)
```

**触发条件：** userInput 包含 `; rm -rf /` 等 shell 元字符  
**检查点：** `exec.Command`、`os/exec`、`syscall.Exec` 调用处

---

## 路径穿越

```go
// ❌ 危险：路径拼接前未清理
filePath := filepath.Join(baseDir, userInput)
// userInput = "../../etc/passwd" 可读取任意文件

// ✅ 安全：清理后验证前缀
cleanPath := filepath.Clean(filepath.Join(baseDir, userInput))
if !strings.HasPrefix(cleanPath, baseDir) {
    return errors.New("invalid path")
}
```

**触发条件：** userInput 包含 `../` 序列  
**检查点：** 所有文件路径拼接处，特别是 `filepath.Join` + 用户输入

---

## 敏感信息日志

```go
// ❌ 危险：密码/token 直接打印
log.Printf("login: user=%s password=%s", username, password)
log.Printf("token: %s", authToken)

// ✅ 安全：脱敏处理
log.Printf("login: user=%s", username)
```

**检查点：** 所有 `log.Printf`、`fmt.Println`、`zap.Info` 等日志调用，
搜索关键词：`password`、`token`、`secret`、`key`、`credential`

---

## 硬编码密钥

```go
// ❌ 危险：代码中直接写密钥
const apiKey = "sk-1234567890abcdef"
password := "admin123"
jwtSecret := []byte("mysecret")

// ✅ 安全：从环境变量或配置文件读取
apiKey := os.Getenv("API_KEY")
```

**检查点：** 搜索 `password =`、`secret =`、`token =`、`key =`、`apiKey`，
检查赋值是否为字符串字面量

---

## 不安全随机数

```go
// ❌ 危险：math/rand 可预测
import "math/rand"
token := fmt.Sprintf("%d", rand.Int63())

// ✅ 安全：crypto/rand
import "crypto/rand"
b := make([]byte, 32)
rand.Read(b)
token := hex.EncodeToString(b)
```

**触发条件：** 用于生成 session token、CSRF token、密码重置链接等安全相关随机值  
**检查点：** 所有 `math/rand` 使用处，判断是否用于安全相关场景

---

## SSRF（服务端请求伪造）

```go
// ❌ 危险：直接使用用户提供的 URL 发起请求
resp, err := http.Get(userProvidedURL)

// ✅ 安全：验证 URL 的 host 在白名单内
allowedHosts := map[string]bool{"api.example.com": true}
u, _ := url.Parse(userProvidedURL)
if !allowedHosts[u.Host] {
    return errors.New("host not allowed")
}
```

**触发条件：** userProvidedURL 指向内网地址（如 `http://169.254.169.254/`）可访问云元数据

---

## 不安全的反序列化

```go
// ❌ 危险：反序列化不可信数据到接口类型
var result interface{}
json.Unmarshal(userInput, &result)
// 若后续对 result 做类型断言，可能 panic

// ❌ 更危险：使用 encoding/gob 反序列化不可信数据
// gob 可触发任意类型的方法调用
```

**检查点：** `json.Unmarshal`、`gob.Decode`、`yaml.Unmarshal` 的数据来源是否可信
