# Directory Structure Details

## Full Directory Tree

```
project root/
+-- docker/
|   +-- .dockerignore           # global dockerignore, invoked via -f docker/Dockerfile at build time
|   +-- Dockerfile              # main Dockerfile (always points to latest version)
|   +-- env.sh                  # global version variables (VERSION/PROGRAM/ENV), always latest
|   +-- build.sh                # build entry script, reads env.sh, supports --push/--no-cache/--platform
|   |
|   +-- 1.0.0/                  # version snapshot (historical, read-only)
|   |   +-- docker-compose.yml
|   |   +-- env.sh
|   |   +-- README.md
|   |
|   +-- 1.1.0/                  # version snapshot (current version)
|       +-- docker-compose.yml
|       +-- env.sh
|       +-- README.md
|
+-- Makefile                    # build command entry (maintained by cicd-pipeline skill)
```

## File Responsibilities

| File | Responsibility | Update timing |
|------|------|----------|
| `docker/env.sh` | Global version variables, always latest | Modify VERSION field on every version change |
| `docker/build.sh` | Build entry, reads env.sh | Update when build logic changes |
| `docker/.dockerignore` | Exclude files that should not enter the image | Update when project structure changes |
| `docker/{v}/docker-compose.yml` | Compose config for that version | Written only at creation, then read-only |
| `docker/{v}/env.sh` | Variable snapshot for that version | Written only at creation, then read-only |
| `docker/{v}/README.md` | Deployment notes for that version | Written only at creation, then read-only |

## Version Directory Naming Convention

- Strictly follow semantic versioning: `MAJOR.MINOR.PATCH` (e.g. `1.0.0`, `2.1.3`)
- No `v` prefix (directory name is `1.0.0`, not `v1.0.0`)
- Historical version directories are never deleted; preserve complete deployment history
