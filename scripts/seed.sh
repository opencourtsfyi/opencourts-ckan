#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "requests",
#     "python-dotenv",
# ]
# ///

import os
import sys
import requests
from dotenv import load_dotenv


def get_session(api_token: str) -> requests.Session:
    """Create a pre-configured session for CKAN."""
    session = requests.Session()
    # Now every session.post() call automatically has this header
    session.headers.update({"Authorization": api_token})
    return session


def ckan_action(
    session: requests.Session,
    base_url: str,
    action: str,
    data: dict,
    files: dict | None = None,
):
    """Executes a CKAN action using the provided session."""
    url = f"{base_url}/api/3/action/{action}"

    if files:
        resp = session.post(url, data=data, files=files)
    else:
        resp = session.post(url, json=data)

    if resp.status_code == 409:
        print(f"Resource '{data['name']}' already exists.")
        return None
    else:
        resp.raise_for_status()

    parsed_response = resp.json()
    print(f"Resource '{data['name']}' created")
    return parsed_response


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <API_TOKEN>", file=sys.stderr)
        sys.exit(1)

    load_dotenv()
    ckan_port = os.getenv("CKAN_PORT_HOST", "5000")
    ckan_url = f"http://localhost:{ckan_port}"

    api_token = sys.argv[1]

    with get_session(api_token) as session:
        print(f"Seeding CKAN at {ckan_url}...")

        ckan_action(
            session,
            ckan_url,
            "organization_create",
            {"name": "test-org", "title": "Test Organization"},
        )

        ckan_action(
            session,
            ckan_url,
            "package_create",
            {
                "name": "test-package",
                "title": "Test Data Measures For Justice",
                "owner_org": "test-org",
            },
        )

    resources = {
        "scripts/seed_data/nc/data-2013-nc.csv": {
            "package_id": "test-package",
            "name": "Test Data Measures For Justice: NC 2013",
            "url": "",
            "format": "csv"
        },
        "scripts/seed_data/nc/locations.csv": {
            "package_id": "test-package",
            "name": "Test Data Measures For Justice: NC locations",
            "url": "",
            "format": "csv"
        },
        "scripts/seed_data/nc/measures.csv": {
            "package_id": "test-package",
            "name": "Test Data Measures For Justice: NC measures",
            "url": "",
            "format": "csv"
        },
        "scripts/seed_data/nc/filters.csv": {
            "package_id": "test-package",
            "name": "Test Data Measures For Justice: NC filters",
            "url": "",
            "format": "csv"
        }
    }
    for f, payload in resources.items():
        with open(f, "rb") as file:
            ckan_action(
                session,
                ckan_url,
                "resource_create",
                payload,
                files={"upload": file},
            )


if __name__ == "__main__":
    main()
