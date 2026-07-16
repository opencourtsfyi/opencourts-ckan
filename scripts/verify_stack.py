# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "requests",
#     "python-dotenv",
# ]
# ///

"""
FR-18 stack smoke checks for local development.

Verifies the dev stack is reachable: CKAN portal, PostgreSQL, and CKAN storage.
This is a minimal smoke script (not a test framework). Catalogue checks live in
scripts/verify_catalog.py.

Prerequisites: dev stack running (`bin/compose up -d`).

See: https://github.com/opencourtsfyi/opencourts-infra/issues/23
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlparse

import requests
from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parent.parent


def get_base_url() -> str:
    load_dotenv(REPO_ROOT / ".env")
    site_url = os.getenv("CKAN_SITE_URL", "").strip().rstrip("/")
    if site_url:
        return site_url
    port = os.getenv("CKAN_PORT_HOST", "5000")
    return f"http://localhost:{port}"


def request_kwargs(base_url: str) -> dict:
    """TLS settings for local HTTPS with self-signed certificates."""
    host = urlparse(base_url).hostname
    if base_url.startswith("https://") and host in ("localhost", "127.0.0.1"):
        return {"verify": False}
    return {}


def ckan_action(base_url: str, action: str, data: dict | None = None) -> dict:
    url = f"{base_url}/api/3/action/{action}"
    resp = requests.post(
        url,
        json=data or {},
        headers={"Content-Type": "application/json"},
        timeout=30,
        **request_kwargs(base_url),
    )
    resp.raise_for_status()
    body = resp.json()
    if not body.get("success"):
        error = body.get("error", {})
        message = error.get("message", body)
        raise AssertionError(f"{action} failed: {message}")
    return body["result"]


def run_bin(*args: str) -> None:
    cmd = [str(REPO_ROOT / "bin" / args[0]), *args[1:]]
    result = subprocess.run(
        cmd,
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "").strip()
        raise AssertionError(
            f"{' '.join(cmd)} failed (exit {result.returncode})"
            + (f": {detail}" if detail else "")
        )


def verify_portal(base_url: str) -> None:
    result = ckan_action(base_url, "status_show")
    if not result.get("ckan_version"):
        raise AssertionError("status_show did not return ckan_version")
    print(f"OK: portal reachable (status_show, CKAN {result['ckan_version']})")


def verify_db() -> None:
    user = os.getenv("POSTGRES_USER", "postgres")
    db = os.getenv("POSTGRES_DB", "postgres")
    run_bin("compose", "exec", "-T", "db", "pg_isready", "-U", user, "-d", db)
    print(f"OK: database reachable (pg_isready -U {user} -d {db})")


def verify_storage() -> None:
    storage_path = os.getenv("CKAN_STORAGE_PATH", "/var/lib/ckan")
    run_bin("shell", "-c", 'test -w "$CKAN_STORAGE_PATH"')
    print(f"OK: storage writable ({storage_path})")


def main() -> None:
    load_dotenv(REPO_ROOT / ".env")
    base_url = get_base_url()
    print(f"Verifying dev stack at {base_url}...")

    checks = (
        ("portal", lambda: verify_portal(base_url)),
        ("database", verify_db),
        ("storage", verify_storage),
    )

    for name, check in checks:
        try:
            check()
        except (AssertionError, requests.RequestException) as exc:
            print(f"FAIL: {name}: {exc}", file=sys.stderr)
            sys.exit(1)

    print("All stack smoke checks passed.")


if __name__ == "__main__":
    main()
