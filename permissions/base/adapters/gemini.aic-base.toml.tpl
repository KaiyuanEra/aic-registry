# aic 基础策略
# _aic_managed = true
# _aic_version = "1.0.0"
# Gemini CLI 策略文件使用 TOML。User/Admin 策略层级是可靠的；
# Workspace .gemini/policies 虽有文档说明，但目前已知不会生效。
# 此处使用的 [[rule]] 字段：
# - toolName：工具名称或名称列表；shell 命令使用 run_shell_command。
# - commandPrefix：run_shell_command 允许或拒绝的 shell 命令前缀。
# - decision：allow | deny | ask_user。
# - priority：策略层级内取值 0-999；数值越高优先级越高。

[[rule]]
# 只读工具默认允许较为安全。
toolName = ["read_file", "grep_search", "glob"]
decision = "allow"
priority = 100

[[rule]]
# 常见项目命令允许执行，无需每次确认。
toolName      = "run_shell_command"
commandPrefix = ["git ", "go ", "make ", "aic "]
decision      = "allow"
priority      = 100

[[rule]]
# 此基线允许网络下载命令；如果团队要求确认，请移除此规则。
toolName      = "run_shell_command"
commandPrefix = ["curl ", "wget "]
decision      = "allow"
priority      = 100

[[rule]]
# 危险 shell 前缀以更高优先级拒绝。
toolName      = "run_shell_command"
commandPrefix = ["rm -rf ", "sudo "]
decision      = "deny"
priority      = 900
deny_message  = "blocked by aic baseline"

[[rule]]
# 基础文件编辑工具允许用于正常编码流程。
toolName = ["write_file", "replace"]
decision = "allow"
priority = 50
