# aic managed
# _aic_managed = true
# _aic_version = "1.0.0"
# Project-level Codex CLI baseline config. Only after Codex trusts
# the workspace will the project .codex/config.toml be loaded.

# approval_policy controls when Codex requests human approval.
# Valid values: untrusted | on-request | never. on-failure is deprecated.
# Use on-request for interactive development; never for non-interactive runs.
approval_policy = "on-request"

# sandbox_mode controls filesystem and network isolation.
# Valid values: read-only | workspace-write | danger-full-access.
sandbox_mode = "workspace-write"

[sandbox_workspace_write]
# network_access=false blocks network access for shell commands inside the sandbox by default.
network_access         = false
# Do not add system temp directories to writable sandbox roots.
exclude_slash_tmp      = true
exclude_tmpdir_env_var = true
