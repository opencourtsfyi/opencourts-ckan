# Architecture

This document describes how **opencourts-ckan** exposes machine-readable catalogues for automated tools and AI agents. For local setup and day-to-day development commands, see [README.md](README.md).

## Table of contents

- [Overview](#overview)
- [Implementation in this repo](#implementation-in-this-repo)
- [Base URL](#base-url)
- [CKAN Action API](#ckan-action-api)
- [DCAT feeds](#dcat-feeds)
- [Metadata available today](#metadata-available-today)
- [Local verification workflow](#local-verification-workflow)
- [References](#references)

## Overview

OpenCourts uses [CKAN](https://ckan.org/) as the metadata portal. Catalogue access is provided through two complementary layers:

1. **CKAN Action API (primary)** — JSON endpoints at `/api/3/action/*` for listing and retrieving datasets, resources, and organization metadata.
2. **DCAT feeds (secondary)** — standards-based RDF serializations via [ckanext-dcat](https://github.com/ckan/ckanext-dcat) (e.g. `/catalog.jsonld`).

No custom catalogue service is run. The Docker images install and configure CKAN's built-in mechanisms.

```
Client (curl, agent, verify_catalog.py)
        │
        ▼
   CKAN 2.11  ──►  CKAN Action API  (/api/3/action/*)
        │
        └──►  ckanext-dcat  (/catalog.{format}, /dataset/{id}.{format})
        │
        ▼
   PostgreSQL (metadata)  +  Solr (search)
```

## Implementation in this repo

| Component | Location | Role |
|-----------|----------|------|
| `ckanext-dcat` 2.4.3 | `ckan/Dockerfile`, `ckan/Dockerfile.dev` | DCAT RDF catalogue documents |
| `dcat` plugin | `CKAN__PLUGINS` in `.env` / `.env.example` | Enables DCAT endpoints |
| Site URL / DCAT base URI | `ckan/docker-entrypoint.d/02_setup_dcat.sh` | Sets `ckan.site_url` and `ckanext.dcat.base_uri` from `CKAN_SITE_URL` |
| Sample data | `scripts/seed.py` | Creates `test-org` and `test-package` for local verification |
| Seeding (authenticated) | `scripts/seed.py` | Uses API token — write path only |

`CKAN_SITE_URL` must match how you reach CKAN locally (HTTP vs HTTPS, port). It drives download URLs, DCAT URIs, and catalogue document links. After changing it, restart CKAN; re-seed if you need stored resource URLs to update.

## Base URL

| Environment | Typical base URL | Compose file |
|-------------|------------------|--------------|
| Dev (default) | `http://localhost:5000` | `docker-compose.dev.yml` via `bin/compose` |
| Dev with HTTPS | `https://localhost:5000` | Set `USE_HTTPS_FOR_DEV=true` — see [README § Running with HTTPS](README.md#running-with-https) |
| Production-style (nginx) | `https://localhost:8443` | `docker-compose.yml` |

All examples below use `http://localhost:5000`. Substitute your base URL when using HTTPS or nginx.

## CKAN Action API

**Pattern:** every action uses the same HTTP shape:

```http
POST /api/3/action/{action_name}
Content-Type: application/json

{ ...parameters... }
```

**Response shape:**

```json
{
  "help": "http://localhost:5000/api/3/action/help_show?name=package_show",
  "success": true,
  "result": { }
}
```

Interactive API docs: `{base_url}/api` (CKAN web UI).

**Read endpoints (no authentication for public data)** — these return public datasets and resources **without** an `Authorization` header. Omit the header entirely when testing anonymous access.

**`package_search`** — search and list datasets:

```sh
curl -s -X POST "http://localhost:5000/api/3/action/package_search" \
  -H "Content-Type: application/json" \
  -d '{"q": "*:*", "rows": 20}'
```

Returns dataset summaries: `name`, `title`, `notes`, `tags`, `organization`, `metadata_modified`, `resources`, etc.

**`package_list`** — list dataset names:

```sh
curl -s -X POST "http://localhost:5000/api/3/action/package_list" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**`package_show`** — one dataset with full resource list:

```sh
curl -s -X POST "http://localhost:5000/api/3/action/package_show" \
  -H "Content-Type: application/json" \
  -d '{"id": "test-package"}'
```

The `result.resources` array is the resource catalogue (name, format, url, size, mimetype).

**`resource_search`** — search resources across the catalog. `query` must use Solr **field:value** syntax (not free text):

```sh
curl -s -X POST "http://localhost:5000/api/3/action/resource_search" \
  -H "Content-Type: application/json" \
  -d '{"query": "name:measures", "limit": 10}'
```

Common searchable fields include `name`, `format`, `url`, and `description`. To list all resources for a dataset, prefer `package_show`.

**`organization_list`** — list organizations:

```sh
curl -s -X POST "http://localhost:5000/api/3/action/organization_list" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**`organization_show`** — organization metadata:

```sh
curl -s -X POST "http://localhost:5000/api/3/action/organization_show" \
  -H "Content-Type: application/json" \
  -d '{"id": "test-org"}'
```

**Write endpoints (authentication required)** — create, update, and delete actions require an API token in the `Authorization` header. This is unchanged from stock CKAN.

```sh
export CKAN_API_TOKEN="$(./bin/ckan user token add ckan_admin my-test-token | tail -1 | tr -d '[:space:]')"

curl -s -X POST "http://localhost:5000/api/3/action/package_create" \
  -H "Content-Type: application/json" \
  -H "Authorization: $CKAN_API_TOKEN" \
  -d '{"name": "my-dataset", "title": "My Dataset"}'
```

Private datasets are not visible to anonymous callers.

**Health check:**

```sh
curl -s "http://localhost:5000/api/action/status_show"
```

## DCAT feeds

With the `dcat` plugin enabled, CKAN serves catalogue documents in standard RDF formats.

| URL | Format |
|-----|--------|
| `/catalog.rdf` | RDF/XML (default `.rdf`) |
| `/catalog.xml` | RDF/XML |
| `/catalog.ttl` | Turtle |
| `/catalog.jsonld` | JSON-LD |
| `/dataset/{dataset-id}.jsonld` | Single dataset (JSON-LD) |

Examples:

```sh
curl -s "http://localhost:5000/catalog.jsonld" | head
curl -s "http://localhost:5000/catalog.ttl" | head
curl -s "http://localhost:5000/dataset/test-package.jsonld" | head
```

The default catalog path is `/catalog.{_format}` (configurable via `ckanext.dcat.catalog_endpoint`). See [ckanext-dcat endpoint docs](https://docs.ckan.org/projects/ckanext-dcat/en/latest/endpoints.html).

Catalog endpoints support pagination and filtering (e.g. `?page=2`, `?q=budget`). Public datasets appear after [seeding](README.md#seeding-data).

## Metadata available today

Catalogue responses include CKAN-native fields available without custom extensions:

| Field | Where | Notes |
|-------|-------|-------|
| Title, description | `package_show` | `title`, `notes` |
| Tags, groups | `package_show` | `tags`, `groups` |
| Custom key/value | `package_show` | `extras` — extension point for future metadata |
| Resources | `package_show`, `resource_search` | `name`, `format`, `url`, `size`, `mimetype` |
| Organization | `package_show`, `organization_show` | Owning org metadata |
| Last modified | `package_show` | `metadata_modified` |

**Follow-on work (not in current catalogue scope):**

- **FR-6** — structured field-level schema documentation
- **FR-7 / FR-8** — provenance-specific fields and display
- **FR-4** — bulk CSV/JSON download with pagination/filtering

## Local verification workflow

After [setup and seeding](README.md#seeding-data):

```sh
# Anonymous read — should return success: true
curl -s -X POST "http://localhost:5000/api/3/action/package_show" \
  -H "Content-Type: application/json" \
  -d '{"id": "test-package"}'

# DCAT catalogue
curl -s "http://localhost:5000/catalog.jsonld" | head
```

Automated verification (`scripts/verify_catalog.py`) and CI integration are planned as follow-up work.

## References

- [CKAN Action API](https://docs.ckan.org/en/latest/api/index.html)
- [ckanext-dcat documentation](https://docs.ckan.org/projects/ckanext-dcat/)
- OpenCourts SRS §3.2 — machine-readable catalogues ([opencourts-governance](https://github.com/opencourtsfyi/opencourts-governance))
