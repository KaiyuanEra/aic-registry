#!/usr/bin/env bash
# description-score.sh — description 触发质量评分
# 用法：scripts/description-score.sh <path/to/SKILL.md>
# 输出：0–100 分，附详细改进建议
# 退出码：0 = 分数 >= 60，1 = 分数 < 60（建议重写）

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

# 提取 description 字段内容（支持多行 YAML block scalar）
FRONTMATTER="$(awk '/^---/{if(++c==2)exit} c==1{print}' "$TARGET")"
DESCRIPTION="$(echo "$FRONTMATTER" | awk '/^description:/{found=1; sub(/^description:[[:space:]]*(>)?[[:space:]]*/,""); if($0!="")print; next} found && /^[[:space:]]/{print; next} found && /^[^[:space:]]/{exit}' | sed 's/^[[:space:]]*//')"

if [[ -z "$DESCRIPTION" ]]; then
  echo ""
  echo "错误：未找到 description 字段内容" >&2
  exit 1
fi

SCORE=0
DETAIL=()

echo ""
echo "aic description-score — $(realpath "$TARGET")"
echo "────────────────────────────────────────────────────────"
echo ""
echo "Description 内容："
echo "$DESCRIPTION" | sed 's/^/  /'
echo ""
echo "────────────────────────────────────────────────────────"
echo "评分明细："
echo ""

# ── 检查项 1：以动词或功能名词开头（20分）────────────────
FIRST_WORD="$(echo "$DESCRIPTION" | head -1 | awk '{print $1}')"
WEAK_VERBS="(Help|Helps|Assist|Assists|Handle|Handles|Deal|A |An |The |This)"
if echo "$FIRST_WORD" | grep -qiE "^($WEAK_VERBS)"; then
  DETAIL+=("  ✗  [-0 ] 开头动词较弱（\"$FIRST_WORD\"），建议用明确的动作动词（执行/生成/分析/管理）")
else
  SCORE=$((SCORE + 20))
  DETAIL+=("  ✓  [+20] 以有效动词或功能名词开头")
fi

# ── 检查项 2：包含 "Use when" 触发场景（25分）─────────────
if echo "$DESCRIPTION" | grep -qi "use when"; then
  SCORE=$((SCORE + 30))
  DETAIL+=("  ✓  [+30] 包含 'Use when' 触发场景描述")
else
  DETAIL+=("  ✗  [-0 ] 缺少 'Use when' 段落——agent 不知道何时应该触发此 skill")
fi

# ── 检查项 3：包含 "Do NOT use for" 排除边界（20分）───────
if echo "$DESCRIPTION" | grep -qi "do not use\|don't use\|不适用\|不要用于"; then
  SCORE=$((SCORE + 25))
  DETAIL+=("  ✓  [+25] 包含排除边界（Do NOT use for）")
else
  DETAIL+=("  ✗  [-0 ] 缺少 'Do NOT use for' 段落——可能与相邻 skill 产生误触发冲突")
fi

# ── 检查项 4：语言覆盖提示（info，不计分）────────────────
# 评分只看结构完整性，不绑定语言；中英文 description 在同一尺子下评估。
HAS_ZH=false
if echo "$DESCRIPTION" | grep -qP "[\x{4e00}-\x{9fff}]" 2>/dev/null || \
   echo "$DESCRIPTION" | grep -q "[一-龿]"; then
  HAS_ZH=true
fi
HAS_EN=false
if echo "$DESCRIPTION" | grep -qE "[a-zA-Z]{2,}"; then
  HAS_EN=true
fi
if [[ "$HAS_ZH" == true ]]; then
  DETAIL+=("  ℹ  [ 0 ] 包含中文关键词，利于中文提问触发（info，不计分）")
elif [[ "$HAS_EN" == true ]]; then
  DETAIL+=("  ℹ  [ 0 ] 包含英文触发词，利于英文提问触发（info，不计分）")
else
  DETAIL+=("  ⚠  [ 0 ] 未检测到明确触发词，建议在 'Use when' 中补充触发词")
fi

# ── 检查项 5：description 长度合理（10分）────────────────
WORD_COUNT="$(echo "$DESCRIPTION" | wc -w | tr -d ' ')"
if [[ "$WORD_COUNT" -lt 10 ]]; then
  DETAIL+=("  ✗  [-0 ] description 过短（${WORD_COUNT} 词），覆盖场景不足，几乎不会被触发")
elif [[ "$WORD_COUNT" -gt 200 ]]; then
  DETAIL+=("  ⚠  [-0 ] description 过长（${WORD_COUNT} 词），超过 150 词建议检查 skill 是否职责过宽")
  SCORE=$((SCORE + 5))
else
  SCORE=$((SCORE + 10))
  DETAIL+=("  ✓  [+10] description 长度合理（${WORD_COUNT} 词）")
fi

# ── 检查项 6：包含具体场景关键词（10分）──────────────────
SCENARIO_PATTERNS="(when|mention|says|asks about|需要|提到|说.*时|遇到)"
SCENARIO_COUNT="$(echo "$DESCRIPTION" | grep -ciE "$SCENARIO_PATTERNS" || true)"
if [[ "$SCENARIO_COUNT" -ge 2 ]]; then
  SCORE=$((SCORE + 15))
  DETAIL+=("  ✓  [+15] 包含 ${SCENARIO_COUNT} 个具体场景关键词")
elif [[ "$SCENARIO_COUNT" -eq 1 ]]; then
  SCORE=$((SCORE + 8))
  DETAIL+=("  ⚠  [+8 ] 只有 1 个场景关键词，建议补充更多触发场景")
else
  DETAIL+=("  ✗  [-0 ] 缺少具体场景描述，触发率低")
fi

# ── 输出明细 ──────────────────────────────────────────────
for line in "${DETAIL[@]}"; do
  echo "$line"
done

echo ""
echo "────────────────────────────────────────────────────────"
printf "总分：%d / 100\n" "$SCORE"

if [[ "$SCORE" -ge 80 ]]; then
  echo "评级：优秀 ✓  description 质量良好，可以提交"
elif [[ "$SCORE" -ge 60 ]]; then
  echo "评级：合格 ⚠  建议参考 references/description-patterns.md 进一步优化"
else
  echo "评级：不合格 ✗  需要重写 description，参考 references/description-patterns.md"
fi

echo ""
echo "参考：skills/aic-skill-creator/references/description-patterns.md"
echo ""

if [[ "$SCORE" -lt 60 ]]; then
  exit 1
fi
exit 0
