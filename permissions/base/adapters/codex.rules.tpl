# aic managed
# _aic_managed = true
# _aic_version = "1.0.0"

# Codex execpolicy rules use Starlark syntax.
# prefix_rule matches the beginning of the shell command argv list.
# decision valid values: allow | prompt | forbidden.
# Rules apply alongside approval_policy and sandbox_mode.

prefix_rule(pattern=["git"], decision="allow")
prefix_rule(pattern=["go"], decision="allow")
prefix_rule(pattern=["make"], decision="allow")
prefix_rule(pattern=["aic"], decision="allow")
