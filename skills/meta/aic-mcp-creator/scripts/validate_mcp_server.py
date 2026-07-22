#!/usr/bin/env python3
"""Validate one MCP-SERVER.md package and its generated registry entry."""

from __future__ import annotations

import argparse
from collections.abc import Mapping
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import urlparse

try:
    import yaml
except ImportError as exc:
    raise SystemExit("PyYAML is required: python3 -m pip install PyYAML") from exc


NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
SEMVER_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
ENV_NAME_RE = re.compile(r"^[A-Z][A-Z0-9_]*$")
PLACEHOLDER_RE = re.compile(r"\{\{\s*aic\.env\.([A-Z][A-Z0-9_]*)\s*\}\}")
ANY_PLACEHOLDER_RE = re.compile(r"\{\{[^{}]+\}\}")
DURATION_RE = re.compile(
    r"^(?=.)(?:[0-9]+(?:\.[0-9]+)?(?:ns|us|µs|ms|s|m|h))+$"
)
TODO_RE = re.compile(r"(?:\bTODO\b|\[待确认|待用户确认[：:])", re.IGNORECASE)

TARGETS = {"claude", "codex", "gemini", "opencode"}
TRANSPORT_TARGETS = {
    "stdio": TARGETS,
    "sse": {"claude", "gemini"},
    "streamable-http": TARGETS,
}
COMMON_FIELDS = {
    "name",
    "version",
    "description",
    "transport",
    "targets",
    "env-required",
    "env-vars",
    "tags",
    "timeout",
}
TRANSPORT_FIELDS = {
    "stdio": {"command", "args", "cwd", "env"},
    "sse": {"url", "headers"},
    "streamable-http": {"url", "headers"},
}
REQUIRED_FIELDS = {
    "stdio": {"command"},
    "sse": {"url"},
    "streamable-http": {"url"},
}
VARIABLE_ROOTS = {"command", "args", "cwd", "env", "url", "headers"}


class UniqueKeyLoader(yaml.SafeLoader):
    pass


def construct_mapping(loader: UniqueKeyLoader, node: yaml.MappingNode, deep: bool = False):
    mapping = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in mapping:
            raise yaml.constructor.ConstructorError(
                "while constructing a mapping",
                node.start_mark,
                f"duplicate key: {key}",
                key_node.start_mark,
            )
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping


UniqueKeyLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_mapping
)


class Validator:
    def __init__(self, repo_root: Path, server_name: str, allow_todo: bool) -> None:
        self.repo_root = repo_root
        self.server_name = server_name
        self.allow_todo = allow_todo
        self.package_dir = repo_root / "mcp-servers" / server_name
        self.manifest = self.package_dir / "MCP-SERVER.md"
        self.errors: list[str] = []

    def fail(self, message: str) -> None:
        self.errors.append(message)

    def run(self) -> int:
        if not self.manifest.is_file():
            self.fail(f"missing {self.manifest}")
            return self.report()

        metadata, body = self.parse_document()
        if metadata is None:
            return self.report()

        self.validate_metadata(metadata)
        self.validate_body(body)
        self.validate_version_bump(str(metadata.get("version", "")))
        self.validate_index(metadata)
        return self.report()

    def parse_document(self) -> tuple[dict | None, str]:
        text = self.manifest.read_text(encoding="utf-8").replace("\r\n", "\n")
        lines = text.splitlines()
        if not lines or lines[0] != "---":
            self.fail("MCP-SERVER.md must start with an exact --- line")
            return None, ""
        try:
            end = lines.index("---", 1)
        except ValueError:
            self.fail("MCP-SERVER.md is missing the closing --- line")
            return None, ""

        source = "\n".join(lines[1:end])
        try:
            metadata = yaml.load(source, Loader=UniqueKeyLoader)
        except yaml.YAMLError as exc:
            self.fail(f"invalid YAML frontmatter: {exc}")
            return None, ""
        if not isinstance(metadata, dict):
            self.fail("frontmatter must be a YAML mapping")
            return None, ""
        return metadata, "\n".join(lines[end + 1 :]).strip()

    def validate_metadata(self, meta: dict) -> None:
        name = meta.get("name")
        if name != self.server_name:
            self.fail(
                f"name must match directory {self.server_name!r}, got {name!r}"
            )
        if not isinstance(name, str) or not NAME_RE.fullmatch(name):
            self.fail("name must use lowercase letters, digits, and single hyphens")

        version = meta.get("version")
        if not isinstance(version, str) or not SEMVER_RE.fullmatch(version):
            self.fail("version must use MAJOR.MINOR.PATCH")

        description = meta.get("description")
        if not isinstance(description, str) or not description.strip():
            self.fail("description must be a non-empty string")

        transport = meta.get("transport")
        if transport not in TRANSPORT_TARGETS:
            self.fail("transport must be stdio, sse, or streamable-http")
            return

        allowed_fields = COMMON_FIELDS | TRANSPORT_FIELDS[transport]
        unknown = sorted(set(meta) - allowed_fields)
        if unknown:
            self.fail(f"unknown or forbidden fields for {transport}: {', '.join(unknown)}")
        missing = sorted(REQUIRED_FIELDS[transport] - set(meta))
        if missing:
            self.fail(f"missing required fields for {transport}: {', '.join(missing)}")

        self.validate_targets(meta.get("targets"), transport)
        self.validate_transport_fields(meta, transport)
        self.validate_timeout(meta.get("timeout"))
        self.validate_tags(meta.get("tags"))
        self.validate_variables(meta)

    def validate_targets(self, targets: object, transport: str) -> None:
        if not isinstance(targets, list) or not targets:
            self.fail("targets must be a non-empty list")
            return
        if any(not isinstance(target, str) for target in targets):
            self.fail("every target must be a string")
            return
        duplicates = sorted({item for item in targets if targets.count(item) > 1})
        if duplicates:
            self.fail(f"duplicate targets: {', '.join(duplicates)}")
        unknown = sorted(set(targets) - TARGETS)
        if unknown:
            self.fail(f"unsupported targets: {', '.join(unknown)}")
        incompatible = sorted(set(targets) - TRANSPORT_TARGETS[transport])
        if incompatible:
            self.fail(
                f"{transport} is not supported by targets: {', '.join(incompatible)}"
            )

    def validate_transport_fields(self, meta: dict, transport: str) -> None:
        if transport == "stdio":
            self.require_nonempty_string(meta, "command")
            if "args" in meta:
                self.require_string_list(meta["args"], "args", allow_empty=True)
            if "cwd" in meta:
                self.require_nonempty_string(meta, "cwd")
            if "env" in meta:
                self.require_string_map(meta["env"], "env")
            return

        self.require_nonempty_string(meta, "url")
        url = meta.get("url")
        if isinstance(url, str):
            normalized_url = PLACEHOLDER_RE.sub("placeholder", url)
            parsed = urlparse(normalized_url)
            if parsed.scheme not in {"http", "https"} or not parsed.netloc:
                self.fail("url must be an absolute http or https URL")
        if "headers" in meta:
            self.require_string_map(meta["headers"], "headers")

    def validate_timeout(self, timeout: object) -> None:
        if timeout is None:
            return
        if not isinstance(timeout, str) or not DURATION_RE.fullmatch(timeout):
            self.fail("timeout must be a positive Go duration such as 5s, 30s, or 2m")
            return
        if not any(float(amount) > 0 for amount in re.findall(r"([0-9]+(?:\.[0-9]+)?)", timeout)):
            self.fail("timeout must be greater than zero")

    def validate_tags(self, tags: object) -> None:
        if tags is None:
            return
        self.require_string_list(tags, "tags", allow_empty=False)
        if isinstance(tags, list) and len(tags) != len(set(map(str, tags))):
            self.fail("tags must not contain duplicates")

    def validate_variables(self, meta: dict) -> None:
        env_required = meta.get("env-required")
        if type(env_required) is not bool:
            self.fail("env-required must be a YAML boolean")

        declarations = meta.get("env-vars")
        declared: list[str] = []
        if declarations is not None:
            if not isinstance(declarations, list) or not declarations:
                self.fail("env-vars must be a non-empty list when present")
            else:
                for index, declaration in enumerate(declarations):
                    name = self.validate_declaration(declaration, index)
                    if name:
                        declared.append(name)
        duplicates = sorted({name for name in declared if declared.count(name) > 1})
        if duplicates:
            self.fail(f"duplicate env-vars declarations: {', '.join(duplicates)}")

        referenced: set[str] = set()
        for path, value in walk_strings(meta):
            placeholders = list(ANY_PLACEHOLDER_RE.finditer(value))
            if not placeholders:
                continue
            root = str(path[0]) if path else ""
            if root not in VARIABLE_ROOTS:
                self.fail(f"placeholders are not allowed in {format_path(path)}")
                continue
            for match in placeholders:
                exact = PLACEHOLDER_RE.fullmatch(match.group(0))
                if exact is None:
                    self.fail(
                        f"invalid placeholder {match.group(0)!r} in {format_path(path)}"
                    )
                else:
                    referenced.add(exact.group(1))

        declared_set = set(declared)
        for name in sorted(referenced - declared_set):
            self.fail(f"placeholder {name} is not declared in env-vars")
        for name in sorted(declared_set - referenced):
            self.fail(f"env var {name} is declared but not used")

        if env_required is True and not declared:
            self.fail("env-required true requires env-vars")
        if env_required is False and declarations is not None:
            self.fail("env-required false must not include env-vars")
        if env_required is False and referenced:
            self.fail("env-required false must not use placeholders")

    def validate_declaration(self, declaration: object, index: int) -> str | None:
        label = f"env-vars[{index}]"
        if not isinstance(declaration, dict):
            self.fail(f"{label} must be a mapping")
            return None
        allowed = {"name", "description", "required", "target", "default"}
        unknown = sorted(set(declaration) - allowed)
        if unknown:
            self.fail(f"{label} has unknown fields: {', '.join(unknown)}")
        missing = sorted({"name", "description", "required", "target"} - set(declaration))
        if missing:
            self.fail(f"{label} is missing: {', '.join(missing)}")

        name = declaration.get("name")
        if not isinstance(name, str) or not ENV_NAME_RE.fullmatch(name):
            self.fail(f"{label}.name must match ^[A-Z][A-Z0-9_]*$")
            name = None
        description = declaration.get("description")
        if not isinstance(description, str) or not description.strip():
            self.fail(f"{label}.description must be a non-empty string")
        if type(declaration.get("required")) is not bool:
            self.fail(f"{label}.required must be a YAML boolean")
        if declaration.get("target") != "mcp":
            self.fail(f"{label}.target must be mcp")
        if "default" in declaration and not isinstance(declaration["default"], str):
            self.fail(f"{label}.default must be a string")
        return name

    def validate_body(self, body: str) -> None:
        if not body:
            self.fail("Markdown body must not be empty")
            return
        if not re.search(r"^#\s+\S", body, re.MULTILINE):
            self.fail("Markdown body must contain an H1 heading")
        if ANY_PLACEHOLDER_RE.search(body):
            self.fail("Markdown body must not contain aic variable placeholders")
        if not self.allow_todo and TODO_RE.search(body):
            self.fail("Markdown body contains TODO or pending-confirmation text")

    def validate_version_bump(self, version: str) -> None:
        rel = f"mcp-servers/{self.server_name}/MCP-SERVER.md"
        exists = subprocess.run(
            ["git", "-C", str(self.repo_root), "cat-file", "-e", f"HEAD:{rel}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if exists.returncode != 0:
            return
        old = subprocess.run(
            ["git", "-C", str(self.repo_root), "show", f"HEAD:{rel}"],
            text=True,
            capture_output=True,
            check=True,
        ).stdout
        old_meta = parse_frontmatter_only(old)
        old_version = old_meta.get("version") if old_meta else None
        changed = subprocess.run(
            [
                "git",
                "-C",
                str(self.repo_root),
                "diff",
                "--quiet",
                "HEAD",
                "--",
                f"mcp-servers/{self.server_name}",
            ],
            check=False,
        ).returncode
        if changed and version == old_version:
            self.fail(f"package changed but version was not incremented from {old_version}")

    def validate_index(self, meta: dict) -> None:
        index_path = self.repo_root / "mcp-servers" / "index.yaml"
        if not index_path.is_file():
            self.fail("missing mcp-servers/index.yaml; run make index")
            return
        try:
            index = yaml.load(index_path.read_text(encoding="utf-8"), Loader=UniqueKeyLoader)
        except yaml.YAMLError as exc:
            self.fail(f"invalid mcp-servers/index.yaml: {exc}")
            return
        if not isinstance(index, dict) or not isinstance(index.get("mcp_servers"), list):
            self.fail("index must contain an mcp_servers list")
            return
        matches = [
            item
            for item in index["mcp_servers"]
            if isinstance(item, dict) and item.get("name") == meta.get("name")
        ]
        if len(matches) != 1:
            self.fail(f"index must contain exactly one entry for {meta.get('name')!r}")
            return
        entry = matches[0]
        expected = {
            "version": meta.get("version"),
            "description": " ".join(str(meta.get("description", "")).split()),
            "path": f"mcp-servers/{self.server_name}",
        }
        for key, value in expected.items():
            if entry.get(key) != value:
                self.fail(f"index {key} must be {value!r}; run make index")

    def require_nonempty_string(self, mapping: Mapping, key: str) -> None:
        value = mapping.get(key)
        if not isinstance(value, str) or not value.strip():
            self.fail(f"{key} must be a non-empty string")

    def require_string_list(self, value: object, label: str, allow_empty: bool) -> None:
        if not isinstance(value, list) or (not allow_empty and not value):
            self.fail(f"{label} must be {'a ' if allow_empty else 'a non-empty '}list")
            return
        if any(not isinstance(item, str) for item in value):
            self.fail(f"every {label} item must be a string")

    def require_string_map(self, value: object, label: str) -> None:
        if not isinstance(value, dict):
            self.fail(f"{label} must be a mapping")
            return
        if any(not isinstance(key, str) or not isinstance(item, str) for key, item in value.items()):
            self.fail(f"{label} keys and values must be strings")

    def report(self) -> int:
        if self.errors:
            for error in self.errors:
                print(f"ERROR: {error}", file=sys.stderr)
            print(f"FAILED: {len(self.errors)} error(s)", file=sys.stderr)
            return 1
        print(f"PASSED: MCP server package {self.server_name} is valid")
        return 0


def walk_strings(value: object, path: tuple[object, ...] = ()):
    if isinstance(value, str):
        yield path, value
    elif isinstance(value, dict):
        for key, item in value.items():
            yield from walk_strings(item, path + (key,))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            yield from walk_strings(item, path + (index,))


def format_path(path: tuple[object, ...]) -> str:
    result = "frontmatter"
    for part in path:
        result += f"[{part}]" if isinstance(part, int) else f".{part}"
    return result


def parse_frontmatter_only(text: str) -> dict | None:
    lines = text.replace("\r\n", "\n").splitlines()
    if not lines or lines[0] != "---":
        return None
    try:
        end = lines.index("---", 1)
        value = yaml.load("\n".join(lines[1:end]), Loader=UniqueKeyLoader)
    except (ValueError, yaml.YAMLError):
        return None
    return value if isinstance(value, dict) else None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo_root", help="registry repository root")
    parser.add_argument("server_name", help="directory name below mcp-servers")
    parser.add_argument(
        "--allow-todo",
        action="store_true",
        help="allow TODO text only for an explicitly requested scaffold",
    )
    args = parser.parse_args()
    root = Path(args.repo_root).resolve()
    return Validator(root, args.server_name, args.allow_todo).run()


if __name__ == "__main__":
    sys.exit(main())
