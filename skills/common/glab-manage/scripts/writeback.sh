#!/usr/bin/env bash
# writeback.sh — Write GitLab Issue numbers back into dev-plan.md
#
# Usage:
#   writeback.sh --plan dev-plan.md --mapping '{"1.1": 42, "1.2": 43}'
#   writeback.sh --plan dev-plan.md --mapping-file /tmp/issue-map.json
#
# mapping format: {"Task ID": Issue_iid}
#   e.g.: {"1.1": 42, "2.3": 51}
#
# Requires: jq (brew install jq / apt install jq)
# Exit codes: 0 = all writebacks succeeded, 1 = partial failure (outputs unmatched list)

set -euo pipefail

usage() {
    cat >&2 <<'EOF'
Usage:
  writeback.sh --plan dev-plan.md --mapping '{"1.1": 42, "1.2": 43}'
  writeback.sh --plan dev-plan.md --mapping-file /tmp/issue-map.json

Exit codes: 0 = all writebacks succeeded, 1 = partial failure
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
        *)              echo "Unknown argument: $1" >&2; usage ;;
    esac
done

[[ -z "$PLAN" ]]   && { echo "Error: missing --plan argument" >&2; exit 1; }
[[ ! -f "$PLAN" ]] && { echo "Error: file not found: $PLAN" >&2; exit 1; }

if [[ -n "$MAPPING_JSON" ]]; then
    JSON="$MAPPING_JSON"
elif [[ -n "$MAPPING_FILE" ]]; then
    JSON=$(cat "$MAPPING_FILE")
else
    echo "Error: must provide --mapping or --mapping-file" >&2; exit 1
fi

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required (brew install jq)" >&2; exit 1; }
echo "$JSON" | jq empty 2>/dev/null || { echo "Error: invalid mapping JSON format" >&2; exit 1; }

TMPMAP=$(mktemp)
TMPOUT=$(mktemp)
trap 'rm -f "$TMPMAP" "$TMPOUT"' EXIT

# Expand mapping into "task_id issue_num" one per line
echo "$JSON" | jq -r 'to_entries[] | .key + " " + (.value | tostring)' > "$TMPMAP"

# Single awk pass to complete all replacements
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

# Match Task heading line: #### Task 1.1: or #### Task 2.3 ...
/^#{1,6}[[:space:]]+Task[[:space:]]+[0-9]/ {
    tmp = $0
    sub(/.*Task[[:space:]]+/, "", tmp)   # Strip heading prefix
    sub(/[^0-9.].*/, "", tmp)            # Keep numeric ID only, e.g. "1.1"
    current_task = tmp
    in_task = (current_task in mapping) ? 1 : 0
    print; next
}

# Any other heading line resets context
/^#{1,6}[[:space:]]/ {
    in_task = 0
    current_task = ""
    print; next
}

# Within a Task block, replace the first #(pending) placeholder
in_task && /#\(pending\)/ {
    sub(/#\(pending\)/, "#" mapping[current_task])
    matched[current_task] = 1
    in_task = 0   # Replace only once per Task
    replaced++
}

{ print }

END {
    printf "\nWriteback complete: %d Task(s) updated with Issue numbers\n", replaced > "/dev/stderr"
    fail = 0
    for (task in mapping) {
        if (!(task in matched)) {
            if (!fail) printf "\nUnmatched items (fill in manually):\n" > "/dev/stderr"
            printf "  - Task %s → #%s (heading or pending placeholder not found)\n", task, mapping[task] > "/dev/stderr"
            fail = 1
        }
    }
    exit fail
}
' "$PLAN" > "$TMPOUT" || awk_exit=$?

cp "$TMPOUT" "$PLAN"
exit $awk_exit
