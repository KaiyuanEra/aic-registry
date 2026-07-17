# glab CLI 降级方案

> 当 GITLAB_TOKEN 未配置但系统中有 `glab` 时使用。
> glab 需要预先执行 `glab auth login` 完成认证。

---

## 检测 glab 是否可用

```bash
if command -v glab &>/dev/null && glab auth status &>/dev/null 2>&1; then
  echo "glab 可用，使用 CLI 模式"
else
  echo "glab 不可用，请配置 GITLAB_TOKEN 或安装 glab"
fi
```

---

## glab 常用命令

### Milestone（glab 暂不支持直接管理 Milestone）

glab CLI 目前不支持 Milestone 的创建和管理，此场景必须回退到 Web API。

---

### Issue 操作

```bash
# 创建 Issue
glab issue create \
  --title "[Phase 1] 实现 SKILL.md frontmatter 解析" \
  --description "## 任务目标
解析 SKILL.md 的 YAML 头..." \
  --label "phase-1,feat" \
  --milestone "Phase 1: 核心基础模块"

# 查看 Issue 列表
glab issue list --state opened

# 关闭 Issue
glab issue close 42
```

---

## glab 安装方式

```bash
# macOS
brew install glab

# Linux（通过包管理器）
sudo apt install glab        # Debian/Ubuntu
sudo dnf install glab        # Fedora

# 通用（下载二进制）
# 访问 https://gitlab.com/gitlab-org/cli/-/releases 获取最新版本
```

---

## 认证配置

```bash
# 配置公司内部 GitLab
glab auth login --hostname git.ifogging.cn

# 验证认证状态
glab auth status
```

---

## 降级时的功能限制

| 功能 | Web API | glab CLI |
|------|---------|----------|
| 创建 Milestone | ✅ | ❌（需用 API） |
| 创建 Issue | ✅ | ✅ |
| 关联 Issue 到 Milestone | ✅ | ⚠️（通过 --milestone 名称，需已存在） |
| 批量创建 | ✅ | ✅（循环调用） |
| 获取 Issue iid 用于回写 | ✅ | ✅（解析 glab 输出） |

**结论：** 有 Milestone 创建需求时必须使用 Web API。glab 仅适合只需创建 Issue 的场景。
