#!/usr/bin/env python3
"""Exercise the MCP package validator with positive and negative fixtures."""

from __future__ import annotations

import contextlib
import io
from pathlib import Path
import tempfile
import textwrap

from validate_mcp_server import Validator


STDIO = """
---
name: codegraph
version: 1.0.0
description: CodeGraph repository analysis MCP server.
transport: stdio
targets: [claude, codex, gemini, opencode]
command: codegraph
args: [serve, --mcp]
env-required: false
---

# CodeGraph MCP

Provides repository graph analysis through MCP.
"""

SSE = """
---
name: legacy-events
version: 1.0.0
description: Legacy SSE MCP endpoint.
transport: sse
targets: [claude, gemini]
url: https://mcp.example.com/sse
headers:
  Authorization: "Bearer {{ aic.env.MCP_TOKEN }}"
timeout: 30s
env-required: true
env-vars:
  - name: MCP_TOKEN
    description: Access token sent in the Authorization header.
    required: true
    target: mcp
---

# Legacy Events MCP

Connects supported clients to the legacy event stream.
"""

HTTP = """
---
name: issue-tracker
version: 2.1.0
description: Team issue tracker MCP server.
transport: streamable-http
targets: [claude, codex, gemini, opencode]
url: https://mcp.example.com/mcp
timeout: 2m
env-required: false
---

# Issue Tracker MCP

Provides issue lookup and update tools.
"""

HTTP_VARIABLE = HTTP.replace(
    "url: https://mcp.example.com/mcp",
    'url: "{{ aic.env.MCP_URL }}"',
).replace(
    "env-required: false",
    """env-required: true
env-vars:
  - name: MCP_URL
    description: Complete Streamable HTTP MCP endpoint URL.
    required: true
    target: mcp""",
)


def run_case(name: str, document: str, should_pass: bool) -> None:
    with tempfile.TemporaryDirectory(prefix="mcp-creator-test-") as temp:
        root = Path(temp)
        package = root / "mcp-servers" / name
        package.mkdir(parents=True)
        (package / "MCP-SERVER.md").write_text(
            textwrap.dedent(document).lstrip(), encoding="utf-8"
        )
        version = next(
            line.split(":", 1)[1].strip()
            for line in document.splitlines()
            if line.startswith("version:")
        )
        description = next(
            line.split(":", 1)[1].strip()
            for line in document.splitlines()
            if line.startswith("description:")
        )
        index = textwrap.dedent(
            f"""\
            registry_version: "v0.1.0"
            mcp_servers:
              - name: {name}
                version: {version}
                description: {description}
                path: mcp-servers/{name}
            """
        )
        (root / "mcp-servers" / "index.yaml").write_text(index, encoding="utf-8")
        output = io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            result = Validator(root, name, allow_todo=False).run()
        passed = result == 0
        if passed != should_pass:
            raise AssertionError(f"{name}: expected pass={should_pass}\n{output.getvalue()}")


def main() -> None:
    cases = [
        ("codegraph", STDIO, True),
        ("legacy-events", SSE, True),
        ("issue-tracker", HTTP, True),
        ("issue-tracker", HTTP_VARIABLE, True),
        ("legacy-events", SSE.replace("[claude, gemini]", "[claude, codex]"), False),
        ("issue-tracker", HTTP.replace("url:", "command: server\nurl:"), False),
        ("legacy-events", SSE.replace("MCP_TOKEN", "api_key"), False),
        ("codegraph", STDIO.replace("env-required: false", "timeout: 0s\nenv-required: false"), False),
    ]
    for name, document, should_pass in cases:
        run_case(name, document, should_pass)
    print(f"PASSED: {len(cases)} MCP validator self-test cases")


if __name__ == "__main__":
    main()
