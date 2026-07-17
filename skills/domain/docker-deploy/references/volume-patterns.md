# 常见挂载模式参考

## 基础挂载模式

### 1. 数据持久化（Named Volume）

```yaml
volumes:
  - {app-name}-data:/app/data

volumes:
  {app-name}-data:
    driver: local
```

适用：数据库文件、应用状态数据，需要跨容器重启保留。

### 2. 宿主机目录挂载（Bind Mount）

```yaml
volumes:
  - /data/{app-name}/logs:/app/data/logs
  - /data/{app-name}/config:/app/config
```

适用：日志收集（宿主机日志聚合）、配置文件热更新。

### 3. 时区同步（只读）

```yaml
volumes:
  - /etc/localtime:/etc/localtime:ro
  - /etc/timezone:/etc/timezone:ro
```

适用：所有服务，确保容器时区与宿主机一致。

### 4. 配置文件注入

```yaml
volumes:
  - ./config/app.yaml:/app/config/app.yaml:ro
```

适用：需要在不重建镜像的情况下修改配置。

## 常见路径约定

| 用途 | 容器内路径 | 宿主机路径建议 |
|------|-----------|----------------|
| 应用数据 | `/app/data` | `/data/{app-name}/data` |
| 日志 | `/app/data/logs` | `/data/logs/{app-name}` |
| 配置 | `/app/config` | `/data/{app-name}/config` |
| 上传文件 | `/app/uploads` | `/data/{app-name}/uploads` |
