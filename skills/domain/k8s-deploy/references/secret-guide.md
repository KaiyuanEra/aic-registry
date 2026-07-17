# Secret 创建和管理指南

## 为什么不把密码写进 k8s.yaml

Secret 的 `data` 字段值是 base64 编码，**不是加密**。任何人拿到 YAML 文件都能解码出明文。因此：
- 生成的 k8s.yaml 中 Secret 值只填占位符 `{base64-value}`
- 实际值通过 `kubectl create secret` 命令手动创建，或通过外部密钥管理系统注入

## 手动创建 Secret

```bash
# 方式一：从字面量创建
kubectl create secret generic {secret-name} \
  --namespace={namespace} \
  --from-literal=db-password=your-actual-password \
  --from-literal=api-key=your-actual-key

# 方式二：从文件创建
kubectl create secret generic {secret-name} \
  --namespace={namespace} \
  --from-file=config.yaml=./local-config.yaml

# 查看 Secret（值会被 base64 编码显示）
kubectl get secret {secret-name} -n {namespace} -o yaml
```

## 生成 base64 编码

```bash
# macOS / Linux
echo -n "your-value" | base64

# 解码验证
echo "eW91ci12YWx1ZQ==" | base64 -d
```

注意：`echo -n` 的 `-n` 参数很重要，避免末尾换行符被编码进去。

## 在 Deployment 中引用 Secret

```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {secret-name}
        key: db-password
```

## 推荐：使用外部密钥管理

生产环境建议使用：
- **Vault**：HashiCorp Vault + K8s Auth Method
- **K8s External Secrets Operator**：从云厂商 KMS 同步
- **Sealed Secrets**：加密后可安全提交到 Git
