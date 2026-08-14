{
  "_aic_managed": true,
  "_aic_version": "1.0.0",
  "_aic_note": "Managed by aic; use aic permission command to modify",
  "_aic_permissions_note": "permissions.allow/ask/deny merge across scopes; deny takes precedence over ask, ask over allow",
  "_aic_permissions_rule_syntax": "ToolName or ToolName(specifier), e.g. Bash(git *) or Read(./.env)",
  "_aic_default_mode_values": "defaultMode accepts: default, acceptEdits, plan, bypassPermissions, auto; omitted here to keep Claude defaults",
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
