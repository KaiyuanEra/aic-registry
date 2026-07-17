---
name: ims-agent-envvars
description: IMS Agent 传入的环境变量说明
type: reference
---

# IMS Agent 传入的环境变量

脚本运行时 Agent 保证传入以下变量，所有脚本必须优先使用这些变量，不能硬编码路径。

## 核心变量

| 变量 | 说明 | 示例 |
|------|------|------|
| `VERSION_DIR` | 本次安装的绝对路径（IMS 下发时确定） | `/opt/apps/raccoon/1.2.0` |
| `APP_DIR` | 应用根目录 | `/opt/apps/raccoon` |
| `OPERATION` | 操作类型 | `install` / `uninstall` / `rollback` |

## 使用规范

```bash
# 正确：优先使用 Agent 传入的变量，提供 fallback 仅用于本地调试
INSTALL_DIR="${VERSION_DIR:-/opt/apps/{{APP_NAME}}/__VERSION__}"

# 错误：硬编码路径
INSTALL_DIR="/opt/apps/raccoon/1.2.0"
```

## 目录结构约定

```
$APP_DIR/
├── current/   → 软链接 → $VERSION_DIR（当前版本，systemd 模式使用）
├── previous/  → 软链接 → 上一个版本目录（rollback 目标，systemd 模式使用）
├── 1.2.0/     ← VERSION_DIR 示例
└── 1.1.0/     ← previous 指向此处
```

Docker 模式不使用软链接，Agent 直接管理版本目录。

## OPERATION 变量

脚本可根据 `$OPERATION` 区分执行场景：

```bash
case "${OPERATION:-install}" in
    install)   echo "首次安装或升级" ;;
    uninstall) echo "卸载" ;;
    rollback)  echo "回滚" ;;
esac
```

实际上 Agent 会直接调用对应脚本（`install.sh` / `uninstall.sh` / `rollback.sh`），
`OPERATION` 变量主要用于日志输出和条件判断。
