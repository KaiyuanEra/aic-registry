# Security Review

Covers OWASP Top 10 categories directly relevant to code review.

---

## SQL Injection

```go
// DANGEROUS: SQL constructed via string concatenation
query := "SELECT * FROM users WHERE name =  + name + "
db.Query(query)

// SAFE: parameterized query
db.Query("SELECT * FROM users WHERE name = ?", name)
```

**Trigger condition:** name comes from user input; passing `OR\1'='1` can bypass auth
**Check point:** all SQL construction; especially `fmt.Sprintf` + SQL keyword combinations

---

## Command Injection

```go
// DANGEROUS: user input passed to exec
cmd := exec.Command("sh", "-c", "ls " + userInput)

// SAFE: separate arguments; do not go through shell parsing
cmd := exec.Command("ls", userInput)
```

**Trigger condition:** userInput contains `; rm -rf /` or other shell metacharacters
**Check point:** `exec.Command`, `os/exec`, `syscall.Exec` call sites

---

## Path Traversal

```go
// DANGEROUS: path not sanitized before joining
filePath := filepath.Join(baseDir, userInput)
// userInput = "../../etc/passwd" can read arbitrary files

// SAFE: clean then verify prefix
cleanPath := filepath.Clean(filepath.Join(baseDir, userInput))
if !strings.HasPrefix(cleanPath, baseDir) {
    return errors.New("invalid path")
}
```

**Trigger condition:** userInput contains `../` sequences
**Check point:** all file path join sites; especially `filepath.Join` + user input

---

## Sensitive Info in Logs

```go
// DANGEROUS: password/token printed directly
log.Printf("login: user=%s password=%s", username, password)
log.Printf("token: %s", authToken)

// SAFE: mask sensitive data
log.Printf("login: user=%s", username)
```

**Check point:** all `log.Printf`, `fmt.Println`, `zap.Info` log calls;
search keywords: `password`, `token`, `secret`, `key`, `credential`

---

## Hardcoded Secrets

```go
// DANGEROUS: secrets written directly in code
const apiKey = "sk-1234567890abcdef"
password := "admin123"
jwtSecret := []byte("mysecret")

// SAFE: read from environment variables or config files
apiKey := os.Getenv("API_KEY")
```

**Check point:** search for `password =`, `secret =`, `token =`, `key =`, `apiKey`;
check if the assignment is a string literal

---

## Insecure Random Numbers

```go
// DANGEROUS: math/rand is predictable
import "math/rand"
token := fmt.Sprintf("%d", rand.Int63())

// SAFE: crypto/rand
import "crypto/rand"
b := make([]byte, 32)
rand.Read(b)
token := hex.EncodeToString(b)
```

**Trigger condition:** used to generate session tokens, CSRF tokens, password reset links, or other security-related random values
**Check point:** all `math/rand` usage; determine if used in security-related scenarios

---

## SSRF (Server-Side Request Forgery)

```go
// DANGEROUS: directly using user-provided URL to make requests
resp, err := http.Get(userProvidedURL)

// SAFE: verify URL host is in a whitelist
allowedHosts := map[string]bool{"api.example.com": true}
u, _ := url.Parse(userProvidedURL)
if !allowedHosts[u.Host] {
    return errors.New("host not allowed")
}
```

**Trigger condition:** userProvidedURL points to an internal address (e.g. `http://169.254.169.254/`) that can access cloud metadata

---

## Insecure Deserialization

```go
// DANGEROUS: deserializing untrusted data into interface type
var result interface{}
json.Unmarshal(userInput, &result)
// if result is later type-asserted, may panic

// MORE DANGEROUS: using encoding/gob to deserialize untrusted data
// gob can trigger arbitrary type method calls
```

**Check point:** whether the data source for `json.Unmarshal`, `gob.Decode`, `yaml.Unmarshal` is trusted
