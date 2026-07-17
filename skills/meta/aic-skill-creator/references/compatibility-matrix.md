# 三工具兼容性矩阵

> 速查 Claude Code、Codex CLI、Gemini CLI 在 skill 加载机制上的差异。
> 大多数 skill 只需 `.agents/skills/` 路径，无需适配层。

---

## 路径速查

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **项目共享路径** | `.agents/skills/<name>` | `.agents/skills/<name>` | `.agents/skills/<name>` |
| **工具专有路径** | `.claude/skills/<name>` | — | `.gemini/skills/<name>` |
| **全局路径** | `~/.claude/skills/` | `~/.codex/skills/` | `~/.gemini/skills/` |
| **上下文文件** | `CLAUDE.md` | `AGENTS.md` | `GEMINI.md` |

`.agents/skills/` 是三工具的共同项目路径，aic 默认在此创建软链接。

---

## Frontmatter 字段兼容性

| 字段 | Claude Code | Codex CLI | Gemini CLI | aic 要求 |
|------|-------------|-----------|------------|----------|
| `name` | 可选 | **必填** | **必填** | **必填** |
| `description` | 可选 | **必填** | **必填** | **必填** |
| `version` | 不感知 | 不感知 | 不感知 | **必填**（aic 强制） |
| `tags` | 不感知 | 不感知 | 不感知 | 建议填写（aic list 过滤用） |
| `env-required` | 不感知 | 不感知 | 不感知 | 按需（aic 渲染用） |
| `allowed-tools` | **支持** | 不支持 | 不支持 | 仅 Claude 适配层使用 |

**结论：** 标准字段（`name` / `description`）三工具全支持。`allowed-tools` 等专有字段只在对应工具的适配层中使用，写在主 SKILL.md 会被其他工具忽略（无害但增加冗余）。

---

## 触发机制差异

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **触发方式** | LLM 语义匹配 / `/skill-name` 显式调用 | description 语义匹配 | `activate_skill` tool + 用户确认 |
| **路由机制** | 纯 LLM forward pass | 描述语义匹配 | Gemini 自主决策 + 工具调用 |
| **显式调用** | `/skill-name` | `/skills` 或 `$skill` | 需用户手动确认 |
| **描述偏好** | 倾向「不触发」，description 需稍强势 | 语义匹配较敏感 | 用户主动确认，误触发风险低 |

**实践建议：**
- description 写法以 Claude Code 为基准（需要稍微"主动"的描述）
- 同一份 description 对 Codex 和 Gemini 通常也能正常工作

---

## 何时需要适配层

```
需要适配层的条件（满足任意一条）：
  ✓ Claude Code 需要 allowed-tools 约束工具权限
  ✓ 某工具的工作流与其他工具有实质性差异（不只是措辞）
  ✓ Codex 需要 agents/openai.yaml 配置 UI 元数据

不需要适配层的情况（占大多数）：
  - 只是措辞略有不同
  - 只是 description 的细微调整
  - 工作流在三工具中完全一致
```

---

## 适配层目录结构

```
skills/common/<skill-name>/
├── SKILL.md                      ← 三工具共用，放在 .agents/skills/
└── adapters/
    ├── claude/
    │   └── SKILL.md              ← 放在 .claude/skills/（含 allowed-tools）
    ├── codex/
    │   ├── SKILL.md
    │   └── agents/openai.yaml    ← Codex UI 元数据
    └── gemini/
        └── SKILL.md              ← 放在 .gemini/skills/
```

aic 检测到 `adapters/<tool>/` 时，自动为对应工具创建工具专有路径的软链接。

---

## live 重载支持

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **会话中编辑即生效** | ✅ | 需重启 | `/memory reload` |

开发调试 skill 时建议在 Claude Code 中进行，改完立即生效，无需重启工具。

---

## 兼容性验证清单

skill 提交 MR 前检查：

- [ ] 主 SKILL.md 的 `name` 和 `description` 字段均已填写（三工具全需要）
- [ ] `version` 已填写（aic 需要）
- [ ] 如有 `allowed-tools`，已放在 `adapters/claude/SKILL.md` 而非主 SKILL.md
- [ ] 如有 `agents/openai.yaml`，已放在 `adapters/codex/` 目录
- [ ] 运行 `scripts/self-test.sh <skill-name>` 确认三工具路径均可见
