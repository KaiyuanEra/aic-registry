---
name: symlink-strategy
description: systemd 模式软链接管理规范
type: reference
---

# systemd 模式软链接管理规范

## 目录结构

```
$APP_DIR/
├── current  → 软链接 → $VERSION_DIR（当前运行版本）
├── previous → 软链接 → 上一个版本目录（rollback 目标）
├── 1.2.0/   ← 当前 VERSION_DIR
│   └── bin/{{APP_NAME}}
└── 1.1.0/   ← previous 指向此处
    └── bin/{{APP_NAME}}
```

## install.sh 软链接切换逻辑

```bash
# APP_DIR 从 VERSION_DIR 推断（上级目录）
APP_DIR="$(dirname "$VERSION_DIR")"

# 切换前：将 current 当前目标保存为 previous
OLD_VERSION_DIR="$(readlink -f "$APP_DIR/current" 2>/dev/null || true)"
if [ -n "$OLD_VERSION_DIR" ] && [ "$OLD_VERSION_DIR" != "$VERSION_DIR" ]; then
    ln -sfn "$OLD_VERSION_DIR" "$APP_DIR/previous"
fi

# 切换 current 到新版本
ln -sfn "$VERSION_DIR" "$APP_DIR/current"
```

## rollback.sh 软链接读取逻辑

```bash
APP_DIR="$(dirname "$VERSION_DIR")"
ROLLBACK_DIR="$(readlink -f "$APP_DIR/previous" 2>/dev/null || true)"

[ -z "$ROLLBACK_DIR" ] && { echo "❌ previous 软链接不存在，无法回滚"; exit 1; }
[ -f "$ROLLBACK_DIR/bin/{{APP_NAME}}" ] || { echo "❌ 回滚版本 binary 不存在: $ROLLBACK_DIR/bin/{{APP_NAME}}"; exit 1; }

# 切换 current → ROLLBACK_DIR（不更新 previous）
ln -sfn "$ROLLBACK_DIR" "$APP_DIR/current"
```

## 注意事项

- `ln -sfn` 中 `-f` 强制覆盖，`-n` 防止将软链接目标当目录处理
- `readlink -f` 解析绝对路径，避免相对路径问题
- rollback 时不更新 `previous`，保持回滚链不变
- uninstall 时清理软链接：`rm -f "$APP_DIR/current" "$APP_DIR/previous"`
- binary 本身不删除，版本目录由 Agent 管理生命周期

## systemd binary 路径约定

systemd unit 文件中 `ExecStart` 使用软链接路径：

```ini
ExecStart=/opt/apps/{{APP_NAME}}/current/bin/{{APP_NAME}} {{START_ARGS}}
WorkingDirectory=/opt/apps/{{APP_NAME}}/current
```

这样 `systemctl start` 时自动使用 `current` 指向的版本，无需修改 unit 文件。
