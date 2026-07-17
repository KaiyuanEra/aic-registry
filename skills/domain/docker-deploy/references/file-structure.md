# 目录结构详细说明

## 完整目录树

```
项目根目录/
├── docker/
│   ├── .dockerignore           # 全局 dockerignore，构建时通过 -f docker/Dockerfile 调用
│   ├── Dockerfile              # 主 Dockerfile（始终指向最新版本）
│   ├── env.sh                  # 全局版本变量（VERSION/PROGRAM/ENV），始终为最新
│   ├── build.sh                # 构建入口脚本，读取 env.sh，支持 --push/--no-cache/--platform
│   │
│   ├── 1.0.0/                  # 版本快照（历史版本，只读）
│   │   ├── docker-compose.yml
│   │   ├── env.sh
│   │   └── README.md
│   │
│   └── 1.1.0/                  # 版本快照（当前版本）
│       ├── docker-compose.yml
│       ├── env.sh
│       └── README.md
│
└── Makefile                    # 构建命令入口（由 cicd-pipeline skill 维护）
```

## 文件职责说明

| 文件 | 职责 | 更新时机 |
|------|------|----------|
| `docker/env.sh` | 全局版本变量，始终为最新 | 每次版本变更时修改 VERSION 字段 |
| `docker/build.sh` | 构建入口，读取 env.sh | 构建逻辑变更时更新 |
| `docker/.dockerignore` | 排除不需要进入镜像的文件 | 项目结构变更时更新 |
| `docker/{v}/docker-compose.yml` | 该版本的 compose 配置 | 只在创建时写入，之后只读 |
| `docker/{v}/env.sh` | 该版本的变量快照 | 只在创建时写入，之后只读 |
| `docker/{v}/README.md` | 该版本的部署说明 | 只在创建时写入，之后只读 |

## 版本目录命名规范

- 严格遵循语义化版本号：`MAJOR.MINOR.PATCH`（如 `1.0.0`、`2.1.3`）
- 不使用 `v` 前缀（目录名为 `1.0.0`，不是 `v1.0.0`）
- 历史版本目录永不删除，保留完整部署历史
