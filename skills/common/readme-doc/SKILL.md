---
name: readme-doc
version: 1.0.0
description: >
  Generate or update a professional README.md for a project, including badges, project overview,
  tech stack, architecture, project structure, deployment and usage, and license sections.
  Use when creating or rewriting a README, documenting a project for the first time,
  or when user mentions write README, generate docs, project intro, README.md, project description,
  add documentation, update README, write an introduction, project docs, or how to write a readme.
  Do NOT use for API documentation, code comments, CHANGELOG, dev-plan development plans,
  or only updating a single section rather than the whole README.
tags: [docs, readme, dev-workflow]
env-required: false
---

# readme-doc

Generate a structurally complete, visually professional `README.md` for a project, covering six sections.

**Design principle:** understand the project first, then write — extract real information from code and config files; do not fabricate content.

---

## Information Collection (required before generation)

Read in priority order; extract project metadata:

```
1. go.mod / package.json / pyproject.toml / Cargo.toml
   -> project name, language version, key dependencies

2. Directory structure (ls -1 / tree -L 2)
   -> module division, entry files, config file locations

3. Makefile / Dockerfile / docker-compose.yml
   -> build commands, deployment method, environment requirements

4. Existing README.md (if present)
   -> preserve existing accurate content; only supplement/rewrite missing parts

5. Main source entry (cmd/main.go, src/index.ts, etc.)
   -> core functionality description, CLI flags, API routes
```

After collection, confirm with the user:
- One-sentence project description (if the existing one is not accurate enough)
- License type (MIT / Apache-2.0 / private, etc.)
- Contact info (email / GitLab username)

---

## Badge Selection Rules

**Core principle:** badges must correspond one-to-one with the project actual tech stack; do not pile up; do not use technologies not in the project.

Steps:
1. Start from the tech stack list confirmed in the collection phase; match badges one by one
2. Find the corresponding badge code in [references/badges.md](references/badges.md)
3. When not found, search the technology name at https://simpleicons.org/ to get the logo slug and brand color; construct it yourself
4. Badge order: language/runtime -> framework -> database -> message queue -> infrastructure -> License

Based on the collected tech stack, select corresponding badges from below; **only include those actually used**:

```markdown
<!-- Language / Runtime -->
[![Go Version](https://img.shields.io/badge/Go-1.24+-00ADD8?style=flat&logo=go)](https://go.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-20+-339933?style=flat&logo=node.js)](https://nodejs.org/)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat&logo=python)](https://python.org/)
[![Rust](https://img.shields.io/badge/Rust-1.75+-000000?style=flat&logo=rust)](https://rust-lang.org/)

<!-- Database -->
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?style=flat&logo=postgresql)](https://postgresql.org/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=flat&logo=mysql)](https://mysql.com/)
[![SQLite](https://img.shields.io/badge/SQLite-3.x-003B57?style=flat&logo=sqlite)](https://www.sqlite.org/)
[![Redis](https://img.shields.io/badge/Redis-7.x-DC382D?style=flat&logo=redis)](https://redis.io/)
[![MongoDB](https://img.shields.io/badge/MongoDB-7.x-47A248?style=flat&logo=mongodb)](https://mongodb.com/)

<!-- Framework -->
[![Gin](https://img.shields.io/badge/Gin-1.x-00ADD8?style=flat&logo=go)](https://gin-gonic.com/)
[![React](https://img.shields.io/badge/React-18+-61DAFB?style=flat&logo=react)](https://react.dev/)
[![Vue](https://img.shields.io/badge/Vue-3.x-4FC08D?style=flat&logo=vue.js)](https://vuejs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=flat&logo=fastapi)](https://fastapi.tiangolo.com/)

<!-- Infrastructure -->
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?style=flat&logo=docker)](https://docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-ready-326CE5?style=flat&logo=kubernetes)](https://kubernetes.io/)
[![GitLab CI](https://img.shields.io/badge/GitLab_CI-passing-FC6D26?style=flat&logo=gitlab)](https://gitlab.com/)

<!-- License (choose one) -->
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![License](https://img.shields.io/badge/License-Private-red.svg)](LICENSE)
```

More badges in [references/badges.md](references/badges.md).

---

## README Structure Template

Generate strictly in the following order and format:

```markdown
<badge line (space-separated, single line)>

# <Project Name>

> <One-sentence description explaining what the project is and what problem it solves>

---

## Project Overview

<2-4 paragraphs: background and motivation, core feature list (bullets), use cases>

---

## Technology Stack

| Category | Technology | Version | Notes |
|----------|------|------|------|
| Language | Go | 1.24+ | ... |
| Database | ... | ... | ... |
| ... | ... | ... | ... |

---

## Architecture

<Architecture description, 2-3 paragraphs + ASCII diagram or layered description>

Example (choose based on actual situation):

### Layered Architecture
```
+-----------------------------------+
|           CLI / API Layer          |
+-----------------------------------+
|         Business Logic            |
+-----------------------------------+
|      Repository / Storage         |
+-----------------------------------+
```

### Data Flow
```
User Request -> Routing -> Business -> Data -> Response
```

---

## Project Structure

```
<project-name>/
+-- <dir1>/          # description
+-- <dir2>/          # description
|   +-- <subdir>/    # description
|   +-- ...
+-- ...
```

> Show only 2 levels deep; collapse minor directories when there are more than 10 top-level entries.

---

## Deployment and Usage

### Prerequisites

- <runtime> <version>+
- <other dependencies>

### Quick Start

```bash
# 1. Clone the repository
git clone <repo-url>
cd <project>

# 2. Install dependencies / build
<install/build command>

# 3. Configure environment variables
cp .env.example .env
# Edit .env with required configuration

# 4. Start
<start command>
```

### Configuration

| Variable | Required | Default | Description |
|----------|------|--------|------|
| `<VAR>` | yes | — | ... |
| `<VAR>` | no | `<default>` | ... |

### Common Commands

```bash
<command1>   # description
<command2>   # description
```

---

## License and Contact

This project is open-sourced under the [<License>](LICENSE) license.

For questions or suggestions, reach out via:

- GitLab Issues: [Submit Issue](<repo-url>/-/issues)
- Email: <email> (optional)
```

---

## Writing Guidelines

- **Language:** English
- **Badges:** only include technologies actually used; do not pile up
- **Architecture diagrams:** prefer ASCII art; keep under 20 lines; complex systems may use Mermaid
- **Project structure:** show only 2 levels; add brief comments; do not list every file
- **Command examples:** must be directly runnable real commands; no pseudocode
- **Configuration table:** extract from .env.example, config.go, or existing README content; do not guess

---

## Common Edge Cases

| Case | Handling |
|------|----------|
| No License file | Ask user to choose; default to MIT; prompt to create a LICENSE file |
| Existing README is fairly complete | Compare section by section; only supplement missing modules; do not overwrite existing accurate content |
| No .env.example | Scan code for os.Getenv / viper / env: tag to extract variables |
| Pure library project (no CLI/service) | Change deployment section to "Installation and Integration"; focus on import and API examples |
| Monorepo | Top-level README covers overall overview; generate sub-READMEs in each sub-module directory |
| Private project | Use Private license badge; remove Issues link; contact info can be left empty |
