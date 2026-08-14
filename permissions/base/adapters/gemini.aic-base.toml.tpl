# aic baseline policy
# _aic_managed = true
# _aic_version = "1.0.0"
# Gemini CLI policy files use TOML. User/Admin policy levels are reliable;
# Workspace .gemini/policies is documented but currently known not to take effect.
# [[rule]] fields used here:
# - toolName: tool name or name list; shell commands use run_shell_command.
# - commandPrefix: shell command prefixes allowed or denied by run_shell_command.
# - decision: allow | deny | ask_user.
# - priority: 0-999 within the policy level; higher value = higher priority.

[[rule]]
# Allowing read-only tools by default is safer.
toolName = ["read_file", "grep_search", "glob"]
decision = "allow"
priority = 100

[[rule]]
# Common project commands allowed without per-invocation confirmation.
toolName      = "run_shell_command"
commandPrefix = ["git ", "go ", "make ", "aic "]
decision      = "allow"
priority      = 100

[[rule]]
# This baseline allows network download commands; remove this rule if your team requires confirmation.
toolName      = "run_shell_command"
commandPrefix = ["curl ", "wget "]
decision      = "allow"
priority      = 100

[[rule]]
# Dangerous shell prefixes denied at higher priority.
toolName      = "run_shell_command"
commandPrefix = ["rm -rf ", "sudo "]
decision      = "deny"
priority      = 900
deny_message  = "blocked by aic baseline"

[[rule]]
# Basic file editing tools allowed for normal coding workflows.
toolName = ["write_file", "replace"]
decision = "allow"
priority = 50
