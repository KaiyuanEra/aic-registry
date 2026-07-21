#!/usr/bin/env bash
# validate.sh — 校验 SKILL.md 结构合规
# 用法：scripts/validate.sh <path/to/SKILL.md>
# 退出码：0 = 全部通过，1 = 有错误

set -euo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  echo "用法：$0 <path/to/SKILL.md>" >&2
  exit 1
fi

if [[ ! -f "$TARGET" ]]; then
  echo "错误：文件不存在：$TARGET" >&2
  exit 1
fi

ERRORS=0
WARNINGS=0
SKILL_DIR="$(dirname "$TARGET")"
SKILL_DIR_NAME="$(basename "$SKILL_DIR")"

pass()  { echo "  ✓  $*"; }
warn()  { echo "  ⚠  $*"; WARNINGS=$((WARNINGS + 1)); }
fail()  { echo "  ✗  $*"; ERRORS=$((ERRORS + 1)); }

echo ""
echo "aic validate — $(realpath "$TARGET")"
echo "────────────────────────────────────────────────────────"

# ── 1. frontmatter 存在性检查 ──────────────────────────────
echo ""
echo "[1] Frontmatter 结构"

# 检查是否以 --- 开头
if ! head -1 "$TARGET" | grep -q "^---"; then
  fail "SKILL.md 必须以 YAML frontmatter 开头（第一行为 ---）"
else
  pass "frontmatter 开头存在"
fi

# 提取 frontmatter 内容（两个 --- 之间）
FRONTMATTER="$(awk '/^---/{if(++c==2)exit} c==1{print}' "$TARGET")"

# ── 2. 必填字段检查 ────────────────────────────────────────
echo ""
echo "[2] 必填字段"

# name
if ! echo "$FRONTMATTER" | grep -q "^name:"; then
  fail "缺少必填字段：name"
else
  FM_NAME="$(echo "$FRONTMATTER" | grep "^name:" | head -1 | sed 's/name:[[:space:]]*//')"
  pass "name: $FM_NAME"

  # name 与目录名一致性检查
  if [[ "$FM_NAME" != "$SKILL_DIR_NAME" ]]; then
    fail "name 字段（${FM_NAME}）与目录名（${SKILL_DIR_NAME}）不一致，必须完全匹配"
  else
    pass "name 与目录名一致"
  fi
fi

# version
if ! echo "$FRONTMATTER" | grep -q "^version:"; then
  fail "缺少必填字段：version（aic 强制要求语义化版本）"
else
  FM_VER="$(echo "$FRONTMATTER" | grep "^version:" | head -1 | sed 's/version:[[:space:]]*//')"
  # 简单校验 semver 格式 MAJOR.MINOR.PATCH
  if echo "$FM_VER" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+$"; then
    pass "version: ${FM_VER}（格式正确）"
  else
    fail "version 格式不合法（期望 MAJOR.MINOR.PATCH，实际：${FM_VER}）"
  fi
fi

# description
if ! echo "$FRONTMATTER" | grep -q "^description:"; then
  fail "缺少必填字段：description"
else
  pass "description 字段存在"
fi

# tags
if ! echo "$FRONTMATTER" | grep -q "^tags:"; then
  warn "建议添加 tags 字段，方便 aic list 过滤"
else
  pass "tags 字段存在"
fi

# ── 3. env-required 检查 ──────────────────────────────────
echo ""
echo "[3] env-required 规范"

ENV_REQUIRED="$(echo "$FRONTMATTER" | grep "^env-required:" | head -1 | sed 's/env-required:[[:space:]]*//')"
ENV_VAR_NAMES="$(echo "$FRONTMATTER" | sed -n 's/^[[:space:]]*-[[:space:]]*name:[[:space:]]*//p')"

if [[ -n "$ENV_VAR_NAMES" ]]; then
  while IFS= read -r var_name; do
    if echo "$var_name" | grep -qE '^[A-Z][A-Z0-9_]*$'; then
      pass "变量名 $var_name 符合 ^[A-Z][A-Z0-9_]*$"
    else
      fail "变量名 $var_name 不合法；必须匹配 ^[A-Z][A-Z0-9_]*$"
    fi
  done <<< "$ENV_VAR_NAMES"

  DUPLICATE_ENV_VARS="$(echo "$ENV_VAR_NAMES" | sort | uniq -d)"
  if [[ -n "$DUPLICATE_ENV_VARS" ]]; then
    fail "env-vars 中存在重复变量名：$(echo "$DUPLICATE_ENV_VARS" | tr '\n' ' ')"
  else
    pass "env-vars 中无重复变量名"
  fi
fi

if [[ "$ENV_REQUIRED" == "true" ]]; then
  pass "env-required: true"

  # 必须有 env-vars
  if ! echo "$FRONTMATTER" | grep -q "^env-vars:"; then
    fail "env-required: true 时必须声明 env-vars 列表"
  else
    pass "env-vars 字段存在"
  fi

  # 正文中的占位符必须在 env-vars 中声明
  BODY="$(awk 'BEGIN{found=0} /^---/{found++; next} found>=2{print}' "$TARGET")"
  PLACEHOLDERS="$(echo "$BODY" | grep -oE '\{\{[A-Z][A-Z0-9_]*\}\}' | sort -u || true)"
  if [[ -n "$PLACEHOLDERS" ]]; then
    while IFS= read -r ph; do
      VAR_NAME="${ph//[\{\}]/}"
      if echo "$ENV_VAR_NAMES" | grep -qx "$VAR_NAME"; then
        pass "占位符 $ph 已在 env-vars 中声明"
      else
        fail "占位符 $ph 在正文中使用但未在 env-vars 中声明"
      fi
    done <<< "$PLACEHOLDERS"
  fi

  # 检测疑似硬编码的 IP 或密码
  BODY="$(awk 'BEGIN{found=0} /^---/{found++; next} found>=2{print}' "$TARGET")"
  if echo "$BODY" | grep -qE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"; then
    warn "正文中疑似存在硬编码 IP 地址，env-required skill 应使用 {{VAR_NAME}} 占位符"
  fi
  if echo "$BODY" | grep -qiE "(password|passwd|secret|token)[[:space:]]*[:=][[:space:]]*[^{]"; then
    warn "正文中疑似存在硬编码敏感值，请改用 {{VAR_NAME}} 占位符"
  fi

elif [[ "$ENV_REQUIRED" == "false" ]] || [[ -z "$ENV_REQUIRED" ]]; then
  pass "env-required: false（标准 skill，无需环境变量）"
else
  fail "env-required 字段值不合法（期望 true 或 false，实际：${ENV_REQUIRED}）"
fi

# ── 4. 正文长度检查 ───────────────────────────────────────
echo ""
echo "[4] 正文长度"

BODY_LINES="$(awk 'BEGIN{found=0} /^---/{found++; next} found>=2{print}' "$TARGET" | wc -l | tr -d ' ')"
if [[ "$BODY_LINES" -gt 500 ]]; then
  warn "正文长度 ${BODY_LINES} 行，超过建议上限 500 行。考虑将详细内容移到 references/"
elif [[ "$BODY_LINES" -lt 10 ]]; then
  warn "正文过短（${BODY_LINES} 行），skill 指令可能不够充分"
else
  pass "正文长度 ${BODY_LINES} 行（合理范围内）"
fi

# ── 5. 适配层检查（informational）────────────────────────
echo ""
echo "[5] 适配层（可选）"

for TOOL in claude codex gemini; do
  ADAPTER_PATH="$SKILL_DIR/adapters/$TOOL/SKILL.md"
  if [[ -f "$ADAPTER_PATH" ]]; then
    # 适配层也需要完整的 frontmatter
    if ! head -1 "$ADAPTER_PATH" | grep -q "^---"; then
      fail "适配层 adapters/$TOOL/SKILL.md 缺少 frontmatter"
    else
      pass "adapters/$TOOL/SKILL.md 存在且有 frontmatter"
    fi
  fi
done

if [[ ! -d "$SKILL_DIR/adapters" ]]; then
  pass "无适配层（大多数 skill 无需适配层）"
fi

# ── 结果汇总 ──────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────"
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo "✓  校验通过，无错误，无警告"
elif [[ $ERRORS -eq 0 ]]; then
  echo "⚠  校验通过，${WARNINGS} 个警告"
else
  echo "✗  校验失败：${ERRORS} 个错误，${WARNINGS} 个警告"
fi
echo ""

exit $ERRORS
