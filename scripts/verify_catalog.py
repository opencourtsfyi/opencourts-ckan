# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "requests",
#     "python-dotenv",
# ]
# ///

"""
FR-5 catalogue smoke checks for local development.

This is a minimal smoke test script (not a test framework). It verifies anonymous
read access to public catalogue data after running scripts/seed.py.

Broader test infrastructure (pytest, unified test runner, CI smoke tests) is
tracked separately — see the issues below:
* https://github.com/opencourtsfyi/opencourts-infra/issues/17
* https://github.com/opencourtsfyi/opencourts-infra/issues/23
"""

from __future__ import annotations

import os
import sys
from urllib.parse import urlparse

import requests
from dotenv import load_dotenv

# Seeded by scripts/seed.py — must match that script.
TEST_ORG = "test-org"
TEST_PACKAGE = "test-package"
TEST_PACKAGE_TITLE = "Test Data Measures For Justice"
MIN_RESOURCES = 4

def get_base_url() -> str:
    load_dotenv()
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


def verify_status_and_dcat_plugin(base_url: str) -> None:
    # FR-5 smoke test: CKAN reachable and dcat plugin enabled.
    # Generic portal/DB smoke tests to be implemented via
    # https://github.com/opencourtsfyi/opencourts-infra/issues/23.
    result = ckan_action(base_url, "status_show")
    extensions = result.get("extensions", [])
    if "dcat" not in extensions:
        raise AssertionError(
            f"dcat plugin not loaded (extensions: {extensions}). "
            "Add dcat to CKAN__PLUGINS and restart CKAN."
        )
    print("OK: status_show (CKAN up, dcat plugin enabled)")


def verify_package_show(base_url: str) -> None:
    # FR-5: anonymous package_show returns public dataset + resources.
    result = ckan_action(base_url, "package_show", {"id": TEST_PACKAGE})
    if result.get("name") != TEST_PACKAGE:
        raise AssertionError(f"expected package {TEST_PACKAGE!r}, got {result.get('name')!r}")
    if result.get("private"):
        raise AssertionError(f"{TEST_PACKAGE} is private; expected a public dataset")
    resources = result.get("resources", [])
    if len(resources) < MIN_RESOURCES:
        raise AssertionError(
            f"expected at least {MIN_RESOURCES} resources, got {len(resources)}. "
            "Run scripts/seed.py first."
        )
    print(f"OK: package_show ({TEST_PACKAGE}, {len(resources)} resources)")


def verify_package_search(base_url: str) -> None:
    # FR-5: anonymous package_search discovers public datasets.
    result = ckan_action(base_url, "package_search", {"q": "*:*", "rows": 20})
    names = {pkg["name"] for pkg in result.get("results", [])}
    if TEST_PACKAGE not in names:
        raise AssertionError(
            f"{TEST_PACKAGE} not found in package_search results. "
            "Run scripts/seed.py first."
        )
    print(f"OK: package_search (found {TEST_PACKAGE})")


def verify_package_list(base_url: str) -> None:
    # FR-5: anonymous package_list includes seeded public dataset.
    result = ckan_action(base_url, "package_list")
    if TEST_PACKAGE not in result:
        raise AssertionError(
            f"{TEST_PACKAGE} not found in package_list. Run scripts/seed.py first."
        )
    print(f"OK: package_list (found {TEST_PACKAGE})")


def verify_organization_show(base_url: str) -> None:
    # FR-5: anonymous organization_show returns seeded org metadata.
    result = ckan_action(base_url, "organization_show", {"id": TEST_ORG})
    if result.get("name") != TEST_ORG:
        raise AssertionError(f"expected organization {TEST_ORG!r}, got {result.get('name')!r}")
    print(f"OK: organization_show ({TEST_ORG})")


def verify_dcat_catalog(base_url: str) -> None:
    # FR-5: anonymous DCAT catalogue feed includes seeded public dataset.
    # https://github.com/opencourtsfyi/opencourts-ckan/issues/5
    url = f"{base_url}/catalog.jsonld"
    resp = requests.get(url, timeout=30, **request_kwargs(base_url))
    if resp.status_code != 200:
        raise AssertionError(f"GET {url} returned HTTP {resp.status_code}")
    body = resp.text
    if TEST_PACKAGE not in body and TEST_PACKAGE_TITLE not in body:
        raise AssertionError(
            f"catalog.jsonld did not include seeded dataset "
            f"({TEST_PACKAGE!r} or {TEST_PACKAGE_TITLE!r}). Run scripts/seed.py first."
        )
    print("OK: catalog.jsonld (DCAT catalogue includes seeded dataset)")


def main() -> None:
    base_url = get_base_url()
    print(f"Verifying catalogue access at {base_url} (no API token)...")

    checks = (
        verify_status_and_dcat_plugin,
        verify_package_show,
        verify_package_search,
        verify_package_list,
        verify_organization_show,
        verify_dcat_catalog,
    )

    for check in checks:
        try:
            check(base_url)
        except (AssertionError, requests.RequestException) as exc:
            print(f"FAIL: {check.__name__}: {exc}", file=sys.stderr)
            sys.exit(1)

    print("All catalogue smoke checks passed.")


if __name__ == "__main__":
    main()
