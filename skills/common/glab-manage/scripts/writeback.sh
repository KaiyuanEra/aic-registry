#!/usr/bin/env bash
# writeback.sh — 将 GitLab Issue 编号回写到 dev-plan.md
#
# 用法：
#   writeback.sh --plan dev-plan.md --mapping '{"1.1": 42, "1.2": 43}'
#   writeback.sh --plan dev-plan.md --mapping-file /tmp/issue-map.json
#
# mapping 格式：{"Task编号": Issue_iid}
#   例：{"1.1": 42, "2.3": 51}
#
# 依赖：jq（brew install jq / apt install jq）
# 退出码：0 = 全部回写成功，1 = 部分失败（输出未匹配清单）

set -euo pipefail

usage() {
    cat >&2 <<'EOF'
用法：
  writeback.sh --plan dev-plan.md --mapping '{"1.1": 42, "1.2": 43}'
  writeback.sh --plan dev-plan.md --mapping-file /tmp/issue-map.json

退出码：0 = 全部回写成功，1 = 部分失败
EOF
    exit 1
}

PLAN=""
MAPPING_JSON=""
MAPPING_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --plan)         PLAN="$2";         shift 2 ;;
        --mapping)      MAPPING_JSON="$2"; shift 2 ;;
        --mapping-file) MAPPING_FILE="$2"; shift 2 ;;
        -h|--help)      usage ;;
        *)              echo "未知参数: $1" >&2; usage ;;
    esac
done

[[ -z "$PLAN" ]]   && { echo "错误：缺少 --plan 参数" >&2; exit 1; }
[[ ! -f "$PLAN" ]] && { echo "错误：文件不存在：$PLAN" >&2; exit 1; }

if [[ -n "$MAPPING_JSON" ]]; then
    JSON="$MAPPING_JSON"
elif [[ -n "$MAPPING_FILE" ]]; then
    JSON=$(cat "$MAPPING_FILE")
else
    echo "错误：必须提供 --mapping 或 --mapping-file" >&2; exit 1
fi

command -v jq >/dev/null 2>&1 || { echo "错误：需要 jq（brew install jq）" >&2; exit 1; }
echo "$JSON" | jq empty 2>/dev/null || { echo "错误：mapping JSON 格式无效" >&2; exit 1; }

TMPMAP=$(mktemp)
TMPOUT=$(mktemp)
trap 'rm -f "$TMPMAP" "$TMPOUT"' EXIT

# 将 mapping 展开为 "task_id issue_num" 每行一条
echo "$JSON" | jq -r 'to_entries[] | .key + " " + (.value | tostring)' > "$TMPMAP"

# 单次 awk 扫描完成所有替换
awk_exit=0
awk -v mapfile="$TMPMAP" '
BEGIN {
    while ((getline line < mapfile) > 0) {
        n = split(line, parts, " ")
        if (n >= 2) mapping[parts[1]] = parts[2]
    }
    close(mapfile)
    replaced = 0
    in_task = 0
    current_task = ""
}

# 匹配 Task 标题行：#### Task 1.1: 或 #### Task 2.3 ...
/^#{1,6}[[:space:]]+Task[[:space:]]+[0-9]/ {
    tmp = $0
    sub(/.*Task[[:space:]]+/, "", tmp)   # 去掉标题前缀
    sub(/[^0-9.].*/, "", tmp)            # 保留纯数字编号如 "1.1"
    current_task = tmp
    in_task = (current_task in mapping) ? 1 : 0
    print; next
}

# 任何其他标题行重置上下文
/^#{1,6}[[:space:]]/ {
    in_task = 0
    current_task = ""
    print; next
}

# 在 Task 块内替换第一个 #（待创建） 占位符
in_task && /#（待创建）/ {
    sub(/#（待创建）/, "#" mapping[current_task])
    matched[current_task] = 1
    in_task = 0   # 每个 Task 只替换一次
    replaced++
}

{ print }

END {
    printf "\n回写完成：%d 个 Task 更新 Issue 编号\n", replaced > "/dev/stderr"
    fail = 0
    for (task in mapping) {
        if (!(task in matched)) {
            if (!fail) printf "\n未匹配项（需手动填写）：\n" > "/dev/stderr"
            printf "  - Task %s → #%s（未找到标题或待创建占位符）\n", task, mapping[task] > "/dev/stderr"
            fail = 1
        }
    }
    exit fail
}
' "$PLAN" > "$TMPOUT" || awk_exit=$?

cp "$TMPOUT" "$PLAN"
exit $awk_exit
