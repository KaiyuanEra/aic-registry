
# Secret Creation and Management Guide

## Why Not Put Passwords in k8s.yaml

Secret `data` field values are base64 encoded, **not encrypted**. Anyone with the YAML file can decode the plaintext. Therefore:
- Secret values in generated k8s.yaml are filled with placeholders `{base64-value}` only
- Actual values are created manually via `kubectl create secret` or injected via an external secret management system

## Manual Secret Creation

```bash
# Method 1: create from literals
kubectl create secret generic {secret-name} \
  --namespace={namespace} \
  --from-literal=db-password=your-actual-password \
  --from-literal=api-key=your-actual-key

# Method 2: create from file
kubectl create secret generic {secret-name} \
  --namespace={namespace} \
  --from-file=config.yaml=./local-config.yaml

# View Secret (values are base64 encoded)
kubectl get secret {secret-name} -n {namespace} -o yaml
```

## Generating base64 Encoding

```bash
# macOS / Linux
echo -n "your-value" | base64

# Decode to verify
echo "eW91ci12YWx1ZQ==" | base64 -d
```

Note: the `-n` flag in `echo -n` is important; it prevents the trailing newline from being encoded.

## Referencing Secrets in Deployment

```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {secret-name}
        key: db-password
```

## Recommended: External Secret Management

For production, recommend:
- **Vault**: HashiCorp Vault + K8s Auth Method
- **K8s External Secrets Operator**: sync from cloud provider KMS
- **Sealed Secrets**: encrypt then safely commit to Git
