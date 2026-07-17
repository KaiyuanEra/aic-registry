#!/usr/bin/env bash
# self-test.sh — 验证 skill 在三种 AI 工具中是否可见
# 用法：scripts/self-test.sh <skill-name> [project-root]
# 说明：在已执行 `aic install` 的项目目录中运行
#       project-root 默认为当前目录

set -euo pipefail

SKILL_NAME="${1:-}"
PROJECT_ROOT="${2:-$(pwd)}"

if [[ -z "$SKILL_NAME" ]]; then
  echo "用法：$0 <skill-name> [project-root]" >&2
  echo "示例：$0 database-ops /path/to/my-project" >&2
  exit 1
fi

echo ""
echo "aic self-test — skill: $SKILL_NAME"
echo "project: $PROJECT_ROOT"
echo "────────────────────────────────────────────────────────"

ERRORS=0

check_link() {
  local TOOL_NAME="$1"
  local LINK_PATH="$2"
  local REQUIRED="$3"   # "required" or "optional"

  if [[ -L "$LINK_PATH" ]]; then
    TARGET_PATH="$(readlink "$LINK_PATH")"
    if [[ -e "$LINK_PATH" ]]; then
      echo "  ✓  $TOOL_NAME  →  $LINK_PATH"
      echo "             → $(readlink -f "$LINK_PATH" 2>/dev/null || echo "$TARGET_PATH")"
      # 检查目标中的 SKILL.md 是否存在
      if [[ -f "$LINK_PATH/SKILL.md" ]]; then
        echo "             SKILL.md 可读取 ✓"
      else
        echo "             ⚠  SKILL.md 不存在于链接目标中"
        ERRORS=$((ERRORS + 1))
      fi
    else
      echo "  ✗  $TOOL_NAME  →  $LINK_PATH（链接损坏，目标不存在：$TARGET_PATH）"
      ERRORS=$((ERRORS + 1))
    fi
  elif [[ -d "$LINK_PATH" ]]; then
    echo "  ⚠  $TOOL_NAME  →  $LINK_PATH（目录存在但不是软链接，可能是手动创建）"
  else
    if [[ "$REQUIRED" == "required" ]]; then
      echo "  ✗  $TOOL_NAME  →  $LINK_PATH（不存在）"
      ERRORS=$((ERRORS + 1))
    else
      echo "  –  $TOOL_NAME  →  $LINK_PATH（不存在，工具未安装或无适配层）"
    fi
  fi
}

echo ""
echo "[1] 共享路径（三工具均读取）"
SHARED_PATH="$PROJECT_ROOT/.agents/skills/$SKILL_NAME"
check_link "Claude / Codex / Gemini  .agents" "$SHARED_PATH" "required"

echo ""
echo "[2] Claude Code 专有路径（有适配层时使用）"
CLAUDE_PATH="$PROJECT_ROOT/.claude/skills/$SKILL_NAME"
check_link "Claude Code  .claude" "$CLAUDE_PATH" "optional"

echo ""
echo "[3] Gemini CLI 专有路径（有适配层时使用）"
GEMINI_PATH="$PROJECT_ROOT/.gemini/skills/$SKILL_NAME"
check_link "Gemini CLI   .gemini" "$GEMINI_PATH" "optional"

echo ""
echo "[4] Codex CLI 路径说明"
echo "  –  Codex CLI 无专有路径，统一使用 .agents/skills/（见上方 [1]）"

# ── .aicrc 声明检查 ───────────────────────────────────────
echo ""
echo "[5] .aicrc 声明"
AICRC_PATH="$PROJECT_ROOT/.aicrc"
if [[ -f "$AICRC_PATH" ]]; then
  if grep -q "name.*=.*\"$SKILL_NAME\"" "$AICRC_PATH" || \
     grep -q "name.*=.*'$SKILL_NAME'" "$AICRC_PATH"; then
    echo "  ✓  $SKILL_NAME 已在 .aicrc 中声明"
    # 检查版本
    VERSION_LINE="$(grep -A5 "name.*=.*[\"']$SKILL_NAME[\"']" "$AICRC_PATH" | grep "version" | head -1 || true)"
    if [[ -n "$VERSION_LINE" ]]; then
      echo "     $VERSION_LINE"
    fi
    # 检查 env_required
    ENV_LINE="$(grep -A5 "name.*=.*[\"']$SKILL_NAME[\"']" "$AICRC_PATH" | grep "env_required" | head -1 || true)"
    if [[ -n "$ENV_LINE" ]]; then
      echo "     $ENV_LINE"
    fi
  else
    echo "  ✗  $SKILL_NAME 未在 .aicrc 中声明（请先执行 aic install $SKILL_NAME）"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  ⚠  .aicrc 不存在于 $PROJECT_ROOT（请先执行 aic init）"
fi

# ── 结果汇总 ──────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────"
if [[ $ERRORS -eq 0 ]]; then
  echo "✓  $SKILL_NAME 在当前项目中可正常被 AI 工具读取"
else
  echo "✗  发现 ${ERRORS} 个问题，请修复后重新运行"
  echo ""
  echo "常见修复命令："
  echo "  aic init                  # 初始化项目目录结构"
  echo "  aic install $SKILL_NAME   # 安装 skill 并创建链接"
  echo "  aic sync                  # 修复损坏链接"
fi
echo ""

exit $ERRORS
