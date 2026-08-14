---
name: docker-deploy
version: 1.1.1
description: Generate the full set of Docker local deployment files (Dockerfile, docker-compose.yml, build.sh, .dockerignore), output to the docker/ directory. Use when generating Docker deployment files, creating docker-compose, creating a build.sh script, initializing a docker directory, or when user mentions Dockerfile, docker-compose, container deployment, or build.sh. Do NOT use for K8s deployment config generation (use k8s-deploy), CI/CD pipeline config (use cicd-pipeline), or just discussing Docker concepts without needing to generate files.
env-required: false
---

# docker-deploy

Generate the full set of Docker local deployment files based on user-provided project information.

**Not responsible for:** Dockerfile internal compilation logic. Only generates the file skeleton and fills in deployment-related configuration.

---

## Output Directory Structure

```
project root/
+-- docker/
|   +-- .dockerignore           # global dockerignore
|   +-- Dockerfile              # multi-stage build skeleton
|   +-- env.sh                  # build variables (PROGRAM / VERSION / ENV / GOPROXY / APT_MIRROR)
|   +-- build.sh                # build entry script (reads env.sh)
|   +-- docker-compose.yml      # local runtime config
|
+-- Makefile                    # build command entry (maintained by cicd-pipeline)
```

---

## File Generation Spec

### `docker/env.sh`

```bash
#!/bin/bash
# Image build config
# Generated: {timestamp}

PROGRAM={registry}/{team}/{app-name}  # full image name, including registry
VERSION={x.y.z}                        # semantic version
ENV=prod                               # runtime env: prod / dev / staging
GOPROXY=https://goproxy.cn,https://goproxy.io,direct  # Go module proxy (required for builds in China)
APT_MIRROR=mirrors.aliyun.com          # apt mirror (optional: mirrors.tuna.tsinghua.edu.cn)
```

**Requirements:**
- `PROGRAM` format must be strictly `{registry}/{namespace}/{image-name}`, three segments
- No sensitive info (passwords, tokens, etc.) in this file

### `docker/Dockerfile`

**Requirements:**
- Multi-stage build (builder + runtime); builder stage compiles, runtime stage only copies artifacts
- Must declare `ARG GOPROXY` followed by `ENV GOPROXY=$GOPROXY`, positioned before `go mod download`:

```dockerfile
ARG GOPROXY=https://goproxy.cn,https://goproxy.io,direct
ENV GOPROXY=$GOPROXY

RUN go mod download
```

- `go mod download` or `go mod tidy` must be preceded by the above two lines, otherwise container builds in China will fail due to inability to access golang.org
- `ARG VERSION` and `ARG ENV` must also be declared for runtime identification
- Runtime stage uses a minimal base image (`alpine` or `distroless`), without the Go toolchain

**Mirror source config for package managers (whenever apt-get / apk / pip install commands exist, switch to a mirror before installing):**

The mirror is passed via `ARG APT_MIRROR`, defaulting to Aliyun, overridable at build time:

```dockerfile
ARG APT_MIRROR=mirrors.aliyun.com
```

| Base image | Package manager | Mirror config method |
|----------|----------|----------------|
| `debian` / `ubuntu` | `apt-get` | Replace source URL with `ARG APT_MIRROR`; **must use HTTP not HTTPS** (HTTPS handshake fails when ca-certificates is not installed) |
| `alpine` | `apk` | `sed` replace `dl-cdn.alpinelinux.org` with `$APT_MIRROR` |
| `python` | `pip` | `-i http://$APT_MIRROR/pypi/simple --trusted-host $APT_MIRROR` |

debian/ubuntu example:

```dockerfile
ARG APT_MIRROR=mirrors.aliyun.com
# Use HTTP not HTTPS: HTTPS handshake fails when ca-certificates is not installed
RUN sed -i "s|http://deb.debian.org/debian|http://${APT_MIRROR}/debian|g" /etc/apt/sources.list.d/debian.sources \
    && sed -i "s|http://security.debian.org/debian-security|http://${APT_MIRROR}/debian-security|g" /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*
```

alpine example:

```dockerfile
ARG APT_MIRROR=mirrors.aliyun.com
RUN sed -i "s/dl-cdn.alpinelinux.org/${APT_MIRROR}/g" /etc/apk/repositories \
    && apk add --no-cache tzdata ca-certificates
```

**Rule:** When any package install command is detected in the Dockerfile, automatically declare `ARG APT_MIRROR` before that `RUN` block, insert the corresponding source replacement command, and add a comment noting "mirror source, HTTP to avoid certificate issues".

### `docker/build.sh`

See `assets/build.sh.template`.

**Requirements:**
- `set -e` must be preserved
- Argument parsing keeps the `while/case` structure
- All user-visible messages in English

### `docker/docker-compose.yml`

See `assets/docker-compose.yml.template`.

**Requirements:**
- Do not write a `version:` field (deprecated in new Docker Compose; writing it produces a warning)
- `image` field must use `${VARIABLE:-default}` format
- Must include `healthcheck` config
- Log config defaults to `max-size: 100m / max-file: 5`
- Timezone: only mount `/etc/localtime:ro` and set env var `TZ=Asia/Shanghai`; **do not mount `/etc/timezone`** (on some systems this file does not exist or has the wrong type; mounting causes OCI runtime errors)
- Sensitive variables are not written in this file; reference an external `.env` file

### `docker/.dockerignore`

See `assets/.dockerignore.template`.

---

## File Operation Safety Rules

| File | Strategy |
|------|------|
| `docker/env.sh` | When it exists, only modify fields explicitly requested by the user; keep the rest |
| `docker/docker-compose.yml` | Generate wholesale (may overwrite) |
| `docker/.dockerignore` | Generate wholesale (may overwrite) |
| `docker/build.sh` | Generate wholesale (may overwrite) |
| `docker/Dockerfile` | When it exists, ask the user whether to overwrite |

Before any write operation, show what will be done and wait for user confirmation.

---

## Sensitive Information Handling

- `docker-compose.yml` -> reference an external `.env` file, or comment that values are injected via environment variables
- When the user-provided info contains obvious passwords or tokens, remind the user not to put this info in the code repository; use placeholders in generated files

---

## Post-Execution Prompt

```
docker/ directory generated, build command: ./docker/build.sh
For K8s deployment config, continue with the k8s-deploy skill
```
