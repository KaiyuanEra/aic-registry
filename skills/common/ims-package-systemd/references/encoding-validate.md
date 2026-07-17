---
name: encoding-validate
description: UTF-8 编码校验方法
type: reference
---

# UTF-8 编码校验方法

打包脚本在压缩前必须验证所有文本文件（`app.yaml` 和 `*.sh`）为 UTF-8 编码。

## 校验函数

```bash
validate_utf8_file() {
    local file="$1"

    # 优先用 python3（最准确）
    if command -v python3 > /dev/null 2>&1; then
        python3 - "$file" > /dev/null 2>&1 <<'PY'
from pathlib import Path
import sys
Path(sys.argv[1]).read_bytes().decode("utf-8")
PY
        return $?
    fi

    # 次之用 iconv
    if command -v iconv > /dev/null 2>&1; then
        iconv -f UTF-8 -t UTF-8 "$file" > /dev/null 2>&1
        return $?
    fi

    # 最后用 file 命令（仅检测 charset）
    if command -v file > /dev/null 2>&1; then
        file -I "$file" 2>/dev/null | grep -Eq 'charset=(utf-8|us-ascii)$'
        return $?
    fi

    # 无工具可用 → 跳过校验（返回 0）
    return 0
}
```

## 诊断函数

```bash
show_encoding_diagnostics() {
    local file="$1"
    if command -v file > /dev/null 2>&1; then
        echo "   file -I: $(file -I "$file" 2>/dev/null || echo unavailable)" >&2
    fi
    if command -v iconv > /dev/null 2>&1; then
        iconv -f UTF-8 -t UTF-8 "$file" > /dev/null 2>&1
        echo "   iconv exit code: $?" >&2
    fi
}
```

## 使用方式

```bash
for file in "$TEMP_DIR/app.yaml" "$TEMP_DIR/scripts"/*.sh; do
    if ! validate_utf8_file "$file"; then
        echo "文件编码不是 UTF-8: $file" >&2
        show_encoding_diagnostics "$file"
        cleanup
        exit 1
    fi
done
```

## 常见问题

- Windows 编辑器保存的文件可能含 BOM（`\xEF\xBB\xBF`），python3 的 `decode("utf-8")` 会报错
- 使用 `decode("utf-8-sig")` 可容忍 BOM，但 IMS 规范要求无 BOM UTF-8
- 建议在编辑器中配置 "UTF-8 without BOM" 保存格式
