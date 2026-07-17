{
  "_aic_managed": true,
  "_aic_version": "1.0.0",
  "_aic_note": "由 aic 管理；请使用 aic permission 命令修改",
  "_aic_permissions_note": "permissions.allow/ask/deny 会跨作用域合并；deny 优先于 ask，ask 优先于 allow",
  "_aic_permissions_rule_syntax": "ToolName 或 ToolName(specifier)，例如 Bash(git *) 或 Read(./.env)",
  "_aic_default_mode_values": "defaultMode 可选值包括 default、acceptEdits、plan、bypassPermissions、auto；此处省略以保留 Claude 默认值",
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(go *)",
      "Bash(make *)",
      "Bash(aic *)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Read",
      "Grep",
      "Glob",
      "Edit"
    ],
    "ask": [],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(sudo *)"
    ]
  }
}
