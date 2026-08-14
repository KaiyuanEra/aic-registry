
# Common Mount Pattern Reference

## Basic Mount Patterns

### 1. Data Persistence (Named Volume)

```yaml
volumes:
  - {app-name}-data:/app/data

volumes:
  {app-name}-data:
    driver: local
```

Use case: database files, application state data that needs to survive container restarts.

### 2. Host Directory Mount (Bind Mount)

```yaml
volumes:
  - /data/{app-name}/logs:/app/data/logs
  - /data/{app-name}/config:/app/config
```

Use case: log collection (host log aggregation), config file hot reload.

### 3. Timezone Sync (read-only)

```yaml
volumes:
  - /etc/localtime:/etc/localtime:ro
  - /etc/timezone:/etc/timezone:ro
```

Use case: all services, ensuring container timezone matches the host.

### 4. Config File Injection

```yaml
volumes:
  - ./config/app.yaml:/app/config/app.yaml:ro
```

Use case: modifying config without rebuilding the image.

## Common Path Conventions

| Purpose | Container path | Suggested host path |
|------|-----------|----------------|
| App data | `/app/data` | `/data/{app-name}/data` |
| Logs | `/app/data/logs` | `/data/logs/{app-name}` |
| Config | `/app/config` | `/data/{app-name}/config` |
| Uploads | `/app/uploads` | `/data/{app-name}/uploads` |
