---
name: k8s-deploy
version: 1.1.1
description: Generate K8s full deployment files (k8s.yaml, with ConfigMap+Secret+Deployment+Service+Ingress) and incremental update files (update.yaml, Deployment only), keeping the Deployment spec strictly consistent across both files. Use when generating K8s deployment files, creating k8s yaml, creating Deployment/Service/Ingress config, updating k8s image version, or generating incremental update files, or when user mentions K8s, Kubernetes, or kubectl. Do NOT use for Docker Compose deployment (use docker-deploy), CI/CD config (use cicd-pipeline), or Helm Chart generation.
env-required: false
---

# k8s-deploy

Generate K8s full deployment files and incremental update files based on user-provided service information.

**Not responsible for:** cluster connection, kubectl execution, or Secret values (only generates the structure; values are filled by the user).

---

## Prerequisite Check

**Before any generation, check whether the following files exist:**

| File | Description |
|------|------|
| `docker/Dockerfile` | Image build definition |
| `docker/build.sh` | Image build script |
| `docker/env.sh` | Build variables (PROGRAM / VERSION / ENV) |

**Check logic:**

```
If all files exist -> proceed with k8s-deploy

If any file is missing -> stop and prompt the user:
  "Image build files are missing (docker/Dockerfile or docker/build.sh).
   K8s deployment depends on local image build capability. Please run the docker-deploy skill
   to generate build files first, then return to continue K8s config generation."
  And ask: switch to docker-deploy now?
```

If the user confirms switching -> run docker-deploy, then automatically continue k8s-deploy.
If the user skips (has external CI building images) -> record user confirmation, continue generation, but note in the post-execution prompt that images must be built manually.

---

## Output Directory Structure

```
docker/
+-- k8s.yaml        # Full: ConfigMap + Secret + Deployment + Service + Ingress
+-- update.yaml     # Incremental: Deployment only (for rolling updates)
```

---

## Full vs Incremental Design Principles

| File | Purpose | Resources included |
|------|------|----------|
| `k8s.yaml` | First deployment / environment rebuild | ConfigMap + Secret + Deployment + Service + Ingress |
| `update.yaml` | Daily iteration, only rolling image updates | Deployment only |

**Core constraints:**
- The Deployment spec in both files must be strictly consistent (image/resources/volumeMounts/env/probes)
- When the image version changes, the image field in both files is updated synchronously

---

## Resource Order (k8s.yaml)

1. ConfigMap — application config file mount
2. Secret — sensitive info (values are base64; generate structure, user fills values)
3. Deployment — application deployment
4. Service — service exposure (ClusterIP / NodePort)
5. Ingress — ingress routing (if needed)

---

## File Generation Spec

See `assets/k8s.yaml.template` and `assets/update.yaml.template`.

**Key field rules:**
- `image` format: `{registry}/{namespace}/{image-name}:{version}`
- `imagePullPolicy: Always`
- `livenessProbe` and `readinessProbe` must be configured
- `resources.limits` and `resources.requests` must be configured

---

## Resource Config Defaults

| Service size | CPU limits | CPU requests | Memory limits | Memory requests |
|----------|------------|--------------|---------------|-----------------|
| Small | 500m | 200m | 1Gi | 512Mi |
| Medium | 1000m | 600m | 3Gi | 2Gi |
| Large | 2000m | 1000m | 6Gi | 4Gi |

When the user does not provide values, select an appropriate size based on the service description and explain the choice in a comment. See `references/resource-presets.md`.

---

## Secret Handling Rules

- Generate the Secret resource structure; `data` field values are filled with `{base64-value}` placeholder only
- Add a comment at the top of the file with the base64 generation command: `echo -n "your-value" | base64`
- Never write actual passwords into generated files
- Remind the user: actual Secret values should be created manually via `kubectl create secret`

See `references/secret-guide.md`.

---

## Image Version Update

When the user says "update image to X.Y.Z":

1. Modify all image fields in `docker/k8s.yaml` and `docker/update.yaml`
2. Synchronously update `metadata.labels.version` and `template.labels.version`
3. Prompt the user to choose the update method:

```
No ConfigMap changes -> recommend incremental update: kubectl apply -f docker/update.yaml
ConfigMap changes -> full update: kubectl apply -f docker/k8s.yaml
```

---

## Deployment Consistency Check

Cross-check during generation to ensure the following fields are identical in `k8s.yaml` and `update.yaml`:
- `image`
- `resources` (limits/requests)
- `volumeMounts`
- `env` (secretKeyRef references)
- `livenessProbe` / `readinessProbe`

---

## Post-Execution Prompt

```
K8s config generated: docker/k8s.yaml and docker/update.yaml
First deployment: kubectl apply -f docker/k8s.yaml
Daily update: kubectl apply -f docker/update.yaml
```
