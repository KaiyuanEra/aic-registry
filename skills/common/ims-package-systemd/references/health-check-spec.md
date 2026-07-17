---
name: health-check-spec
description: IMS 健康检查规范
type: reference
---

# 健康检查规范

## 健康检查端点要求

应用必须在 `HEALTH_PORT`（默认 50099）暴露 HTTP 健康检查端点：

```
GET http://127.0.0.1:{{HEALTH_PORT}}/health
```

- 健康时返回 HTTP 2xx
- 不健康时返回非 2xx 或超时

## 脚本中的健康检查逻辑

```bash
HEALTH_URL="http://127.0.0.1:{{HEALTH_PORT}}/health"
MAX_RETRIES=10
RETRY_COUNT=0

# 等待服务启动
sleep 5

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -sf "$HEALTH_URL" > /dev/null 2>&1; then
        echo "健康检查通过"
        exit 0
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "尝试 $RETRY_COUNT/$MAX_RETRIES ..."
    sleep 3
done

# 健康检查失败 → exit 1，Agent 触发 rollback.sh
exit 1
```

## 端口释放等待逻辑

在 `install.sh` / `rollback.sh` 中，停止旧服务后需等待端口释放：

```bash
HEALTH_PORT="{{HEALTH_PORT}}"
MAX_RETRIES=5

is_port_in_use() {
    if command -v ss &> /dev/null; then
        ss -ltnH "sport = :${HEALTH_PORT}" 2>/dev/null | grep -q . && return 0
    elif command -v lsof &> /dev/null; then
        lsof -nP -iTCP:"${HEALTH_PORT}" -sTCP:LISTEN 2>/dev/null | awk 'NR>1' | grep -q . && return 0
    fi
    # Docker 容器维度检测
    docker container ls --filter "status=running" --filter "publish=${HEALTH_PORT}" \
        --format '{{.Names}}' | grep -q . && return 0
    return 1
}

retry=0
while [ $retry -lt $MAX_RETRIES ]; do
    is_port_in_use || return 0
    retry=$((retry + 1))
    sleep 1
done
echo "端口 ${HEALTH_PORT} 仍被占用" && exit 1
```

## start.sh 的端口冲突检测

`start.sh` 与 `install.sh` 不同：检测到端口占用直接 `exit 1`，不等待。

```bash
# start.sh 端口冲突检测（检测到即退出，不重试）
if is_port_in_use; then
    echo "端口 ${HEALTH_PORT} 已被占用，启动已终止"
    exit 1
fi
```
