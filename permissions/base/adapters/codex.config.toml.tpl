# aic 管理
# _aic_managed = true
# _aic_version = "1.0.0"
# 项目级 Codex CLI 基线配置。只有在 Codex 信任工作区后，
# 才会加载项目的 .codex/config.toml。

# approval_policy 控制 Codex 何时请求人工批准。
# 可选值：untrusted | on-request | never。on-failure 已废弃。
# 交互式开发使用 on-request；非交互式运行使用 never。
approval_policy = "on-request"

# sandbox_mode 控制文件系统和网络隔离。
# 可选值：read-only | workspace-write | danger-full-access。
sandbox_mode = "workspace-write"

[sandbox_workspace_write]
# network_access=false 默认阻止沙箱内 shell 命令访问网络。
network_access         = false
# 不将系统临时目录加入可写沙箱根目录。
exclude_slash_tmp      = true
exclude_tmpdir_env_var = true
