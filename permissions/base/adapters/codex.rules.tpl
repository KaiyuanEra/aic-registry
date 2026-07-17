# aic 管理
# _aic_managed = true
# _aic_version = "1.0.0"

# Codex execpolicy 规则使用 Starlark 语法。
# prefix_rule 匹配 shell 命令 argv 列表的开头。
# decision 可选值：allow | prompt | forbidden。
# 规则会与 approval_policy 和 sandbox_mode 一起生效。

prefix_rule(pattern=["git"], decision="allow")
prefix_rule(pattern=["go"], decision="allow")
prefix_rule(pattern=["make"], decision="allow")
prefix_rule(pattern=["aic"], decision="allow")
