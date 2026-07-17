---
name: k8s-deploy
version: 1.1.1
description: 生成 K8s 全量部署文件（k8s.yaml，含 ConfigMap+Secret+Deployment+Service+Ingress）和增量更新文件（update.yaml，仅含 Deployment），两文件 Deployment spec 保持严格一致。Use when 帮我生成 K8s 部署文件、生成 k8s yaml、创建 Deployment/Service/Ingress 配置、更新 k8s 镜像版本、生成增量更新文件，or when user mentions K8s / Kubernetes / kubectl。Do NOT use for Docker Compose 部署（→ docker-deploy）、CI/CD 配置（→ cicd-pipeline）、Helm Chart 生成。
env-required: false
---

# k8s-deploy

根据用户提供的服务信息，生成 K8s 全量部署文件和增量更新文件。

**不负责：** 集群连接、kubectl 操作执行、Secret 的值（只生成结构，值由用户填写）。

---

## 前置依赖检查

**执行任何生成操作前，先检查以下文件是否存在：**

| 文件 | 说明 |
|------|------|
| `docker/Dockerfile` | 镜像构建定义 |
| `docker/build.sh` | 镜像构建脚本 |
| `docker/env.sh` | 构建变量（PROGRAM / VERSION / ENV） |

**检查逻辑：**

```
若以上文件均存在 → 继续执行 k8s-deploy 流程

若任意文件缺失 → 停止，提示用户：
  "检测到镜像构建文件缺失（docker/Dockerfile 或 docker/build.sh）。
   K8s 部署依赖本地镜像构建能力，请先执行 docker-deploy skill 生成构建文件，
   再回来继续 K8s 配置生成。"
  并询问：是否现在切换到 docker-deploy？
```

若用户确认切换 → 执行 docker-deploy 流程，完成后自动继续 k8s-deploy。
若用户跳过（已有外部 CI 构建镜像）→ 记录用户确认，继续生成，但在执行后提示中注明镜像需手动构建。

---

## 输出目录结构

```
docker/
├── k8s.yaml        # 全量：ConfigMap + Secret + Deployment + Service + Ingress
└── update.yaml     # 增量：仅 Deployment（用于滚动更新）
```

---

## 全量 vs 增量设计原则

| 文件 | 用途 | 包含资源 |
|------|------|----------|
| `k8s.yaml` | 首次部署 / 重建环境 | ConfigMap + Secret + Deployment + Service + Ingress |
| `update.yaml` | 日常迭代，只滚动更新镜像 | 仅 Deployment |

**核心约束：**
- 两文件 Deployment spec 必须严格一致（image/resources/volumeMounts/env/probes）
- 镜像版本变更时，两个文件的 image 字段同步更新

---

## 资源顺序（k8s.yaml）

1. ConfigMap — 应用配置文件挂载
2. Secret — 敏感信息（值为 base64，生成结构，值需用户填写）
3. Deployment — 应用部署
4. Service — 服务暴露（ClusterIP / NodePort）
5. Ingress — 入口路由（如需）

---

## 文件生成规范

参考 `assets/k8s.yaml.template` 和 `assets/update.yaml.template`。

**关键字段规范：**
- `image` 格式：`{registry}/{namespace}/{image-name}:{version}`
- `imagePullPolicy: Always`
- `livenessProbe` 和 `readinessProbe` 必须配置
- `resources.limits` 和 `resources.requests` 必须配置

---

## 资源配置默认值

| 服务规模 | CPU limits | CPU requests | Memory limits | Memory requests |
|----------|------------|--------------|---------------|-----------------|
| 小型 | 500m | 200m | 1Gi | 512Mi |
| 中型 | 1000m | 600m | 3Gi | 2Gi |
| 大型 | 2000m | 1000m | 6Gi | 4Gi |

用户未提供时，根据服务描述选择合适规模，并在注释中说明选择理由。详见 `references/resource-presets.md`。

---

## Secret 处理规范

- 生成 Secret 资源结构，`data` 字段值只填写 `{base64-value}` 占位符
- 文件顶部注释说明生成 base64 的命令：`echo -n "your-value" | base64`
- 严禁将实际密码写入生成文件
- 提示用户：Secret 的实际值应通过 `kubectl create secret` 命令手动创建

详见 `references/secret-guide.md`。

---

## 镜像版本更新

用户说"更新镜像到 X.Y.Z"时：

1. 修改 `docker/k8s.yaml` 和 `docker/update.yaml` 中所有 image 字段
2. `metadata.labels.version` 和 `template.labels.version` 同步更新
3. 提示用户选择更新方式：

```
ConfigMap 无变更 → 推荐增量更新：kubectl apply -f docker/update.yaml
ConfigMap 有变更 → 全量更新：kubectl apply -f docker/k8s.yaml
```

---

## Deployment 一致性检查

生成时交叉检查，确保 `k8s.yaml` 和 `update.yaml` 中以下字段值相同：
- `image`
- `resources`（limits/requests）
- `volumeMounts`
- `env`（secretKeyRef 引用）
- `livenessProbe` / `readinessProbe`

---

## 执行后提示

```
K8s 配置已生成：docker/k8s.yaml 和 docker/update.yaml
首次部署：kubectl apply -f docker/k8s.yaml
日常更新：kubectl apply -f docker/update.yaml
```
