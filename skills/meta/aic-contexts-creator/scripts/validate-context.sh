#!/usr/bin/env bash

set -euo pipefail

repo_root="${1:-.}"
context_name="${2:-project-coding-guideline}"
allow_todo="${3:-}"
context_dir="$repo_root/contexts/$context_name"
manifest="$context_dir/CONTEXT.md"
index="$repo_root/contexts/index.yaml"
errors=0
warnings=0

fail() { printf 'ERROR: %s\n' "$*" >&2; errors=$((errors + 1)); }
warn() { printf 'WARN: %s\n' "$*" >&2; warnings=$((warnings + 1)); }
pass() { printf 'OK: %s\n' "$*"; }

for file in "$manifest" "$index"; do
  if [[ ! -f "$file" ]]; then
    fail "missing $file"
  fi
done
if (( errors > 0 )); then
  exit 1
fi

if [[ "$(sed -n '1p' "$manifest")" != "---" ]]; then
  fail "CONTEXT.md must start with ---"
fi
frontmatter="$(awk 'NR == 1 && $0 == "---" { open=1; next } open && $0 == "---" { found=1; exit } open { print } END { if (!found) exit 2 }' "$manifest")" || fail "CONTEXT.md is missing the closing ---"

field() {
  local key="$1"
  printf '%s\n' "$frontmatter" | sed -n "s/^${key}:[[:space:]]*//p" | head -n 1
}

name="$(field name)"
version="$(field version)"
description="$(field description)"
content_ref="$(field content)"
env_required="$(field env-required)"

[[ "$name" == "$context_name" ]] || fail "name must match directory '$context_name', got '$name'"
[[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "name must use lowercase letters, digits, and hyphens"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "version must use MAJOR.MINOR.PATCH, got '$version'"
[[ -n "$description" ]] || fail "description must be non-empty and remain on the key line"
[[ -n "$content_ref" ]] || fail "content must be non-empty"
[[ "$content_ref" != /* && "$content_ref" != *..* ]] || fail "content must be a package-relative path without .."
[[ "$env_required" == "true" || "$env_required" == "false" ]] || fail "env-required must be true or false"

content="$context_dir/$content_ref"
if [[ ! -f "$content" ]]; then
  fail "content file does not exist: $content"
fi
targets="$(printf '%s\n' "$frontmatter" | awk '/^targets:/ { capture=1; next } capture && /^[^[:space:]]/ { exit } capture && /^[[:space:]]*-[[:space:]]+/ { print }')"
if [[ -z "$targets" ]]; then
  fail "targets must contain at least one item"
fi

env_rows="$(printf '%s\n' "$frontmatter" | awk '
  function trim_value(line) { sub(/^[^:]+:[[:space:]]*/, "", line); return line }
  function emit() {
    if (have) print var_name sep description sep required sep target sep default_value
    var_name=""; description=""; required=""; target=""; default_value=""; have=0
  }
  BEGIN { sep=sprintf("%c", 28) }
  /^env-vars:/ { in_vars=1; next }
  in_vars && /^[^[:space:]]/ { emit(); in_vars=0 }
  in_vars && /^[[:space:]]*-[[:space:]]+name:/ { emit(); var_name=trim_value($0); have=1; next }
  in_vars && /^[[:space:]]+description:/ { description=trim_value($0); next }
  in_vars && /^[[:space:]]+required:/ { required=trim_value($0); next }
  in_vars && /^[[:space:]]+target:/ { target=trim_value($0); next }
  in_vars && /^[[:space:]]+default:/ { default_value=trim_value($0); next }
  END { if (in_vars) emit() }
')"

declared_vars=""
if [[ -n "$env_rows" ]]; then
  while IFS=$'\034' read -r var_name var_description var_required var_target var_default; do
    declared_vars="${declared_vars}${declared_vars:+$'\n'}${var_name}"
    [[ "$var_name" =~ ^[A-Z][A-Z0-9_]*$ ]] || fail "env var name must match ^[A-Z][A-Z0-9_]*$: '$var_name'"
    [[ -n "$var_description" ]] || fail "env var $var_name requires description"
    [[ "$var_required" == "true" || "$var_required" == "false" ]] || fail "env var $var_name required must be true or false"
    [[ "$var_target" == "context" ]] || fail "env var $var_name target must be context"
  done <<< "$env_rows"

  duplicate_vars="$(printf '%s\n' "$declared_vars" | sort | uniq -d)"
  if [[ -n "$duplicate_vars" ]]; then
    fail "duplicate env var declarations: $(printf '%s' "$duplicate_vars" | tr '\n' ' ')"
  fi
fi

if [[ "$env_required" == "true" && -z "$declared_vars" ]]; then
  fail "env-required true requires a non-empty env-vars list"
fi
if [[ "$env_required" == "false" ]] && printf '%s\n' "$frontmatter" | rg -q '^env-vars:'; then
  fail "env-required false must not contain env-vars"
fi

if [[ -f "$content" ]]; then
  if [[ "$(sed -n '1p' "$content")" == "---" ]]; then
    fail "content file must not contain YAML front matter"
  fi

  line_count="$(wc -l < "$content" | tr -d ' ')"
  if (( line_count > 200 )); then
    warn "content has $line_count lines; prefer external references above 200"
  else
    pass "content line count is $line_count"
  fi

  if [[ "$allow_todo" != "--allow-todo" ]] && rg -q '\[TODO|\[Pending user confirmation[：:]' "$content"; then
    fail "content contains TODO placeholders; only explicit scaffold output may use --allow-todo"
  fi

  placeholders="$(rg -o '\{\{[[:space:]]*aic\.env\.[A-Z][A-Z0-9_]*[[:space:]]*\}\}' "$content" 2>/dev/null | sed -E 's/.*aic\.env\.([A-Z][A-Z0-9_]*).*/\1/' | sort -u || true)"
  invalid_placeholders="$(rg -n '\{\{[^}]+\}\}' "$content" 2>/dev/null | rg -v '\{\{[[:space:]]*aic\.env\.[A-Z][A-Z0-9_]*[[:space:]]*\}\}' || true)"
  if [[ -n "$invalid_placeholders" ]]; then
    fail "content contains unsupported template placeholders"
  fi
  if [[ -n "$placeholders" ]]; then
    while IFS= read -r var_name; do
      if ! printf '%s\n' "$declared_vars" | rg -qx "$var_name"; then
        fail "placeholder $var_name is not declared in env-vars"
      fi
    done <<< "$placeholders"
  fi

  if [[ "$env_required" == "false" && -n "$placeholders" ]]; then
    fail "env-required false must not use variable placeholders"
  fi

  if [[ -n "$declared_vars" ]]; then
    while IFS= read -r var_name; do
      if ! printf '%s\n' "$placeholders" | rg -qx "$var_name"; then
        fail "env var $var_name is declared but not used in content"
      fi
    done <<< "$declared_vars"
  fi
fi

manifest_rel="contexts/$context_name/CONTEXT.md"
if git -C "$repo_root" cat-file -e "HEAD:$manifest_rel" 2>/dev/null; then
  old_version="$(git -C "$repo_root" show "HEAD:$manifest_rel" | sed -n 's/^version:[[:space:]]*//p' | head -n 1)"
  if ! git -C "$repo_root" diff --quiet HEAD -- "contexts/$context_name" && [[ "$version" == "$old_version" ]]; then
    fail "context changed but version was not incremented from $old_version"
  fi
fi

index_block="$(awk -v target="$name" '$0 == "    - name: \"" target "\"" { capture=1; print; next } capture && /^    - name:/ { exit } capture { print }' "$index")"
if [[ -z "$index_block" ]]; then
  fail "contexts/index.yaml is missing $name; run make index"
else
  printf '%s\n' "$index_block" | rg -q "^[[:space:]]+version: \"${version}\"$" || fail "index version does not match CONTEXT.md ($version); run make index"
  printf '%s\n' "$index_block" | rg -q "^[[:space:]]+path: \"contexts/${context_name}\"$" || fail "index path is incorrect"
fi

if (( errors > 0 )); then
  printf 'FAILED: %d error(s), %d warning(s)\n' "$errors" "$warnings" >&2
  exit 1
fi
printf 'PASSED: context package %s is valid (%d warning(s))\n' "$context_name" "$warnings"
