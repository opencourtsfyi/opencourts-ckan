# opencourts-ckan

The metadata, pipelines, extensions for the CKAN portion of open courts

## Documentation

- [Architecture](docs/ARCHITECTURE.md) — catalogue APIs (CKAN Action API, DCAT), system design, and local verification
- [Troubleshooting](docs/TROUBLESHOOTING.md) — common local dev problems (ports, WSL2, macOS, volumes)

## Table of contents

- [Documentation](#documentation)
- [Development](#development)
  - [Prerequisites](#prerequisites)
  - [Setup](#setup)
  - [Common commands](#common-commands)
  - [Seeding Data](#seeding-data)
  - [Verifying catalogue access](#verifying-catalogue-access)
  - [Teardown](#teardown)
  - [Remote debugging](#remote-debugging)
  - [Running with HTTPS](#running-with-https)
- [Tracking ckan-docker upstream](#tracking-ckan-docker-upstream)

## Development

This project is forked from [ckan/ckan-docker](https://github.com/ckan/ckan-docker). The upstream [development mode](https://github.com/ckan/ckan-docker?tab=readme-ov-file#development-mode) guide covers Docker internals, `bin/` helper scripts, extensions, HTTPS, and debugging — use it when you need depth beyond this quickstart.

> *Problems starting the stack?* See [Troubleshooting](docs/TROUBLESHOOTING.md).

### Prerequisites

You need [Docker](https://www.docker.com) and [uv](https://github.com/astral-sh/uv). All `bin/` scripts require a **Unix-like shell** (bash). Run commands from a terminal on Linux, on macOS, or inside WSL2 on Windows.

#### Linux

- Install [Docker Engine](https://docs.docker.com/engine/install/) (Compose plugin included on current installs).
- Install [uv](https://docs.astral.sh/uv/getting-started/installation/).

#### macOS

- Install [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/).
- Install [uv](https://docs.astral.sh/uv/getting-started/installation/).
- **Apple Silicon Macs** (M1 and later): CKAN images are `amd64` only — set `export DOCKER_DEFAULT_PLATFORM=linux/amd64` before building. Intel Macs run the images natively and do not need this. See [Troubleshooting → macOS](docs/TROUBLESHOOTING.md#macos).

#### Windows

Windows requires WSL2 and Docker Desktop. Follow the steps below to get your environment set up with the repo using both.

> **NOTE**: If you run into issues, see [Troubleshooting → Windows (WSL2)](docs/TROUBLESHOOTING.md#windows-wsl2).

1. Install WSL2 with Ubuntu:

   ```powershell
   wsl --install -d Ubuntu
   ```

   Restart the machine if prompted.

2. Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop).

3. In Docker Desktop **Settings**:
   - **General:** enable *Use the WSL 2 based engine*
   - **Resources → WSL Integration:** enable integration for Ubuntu
   - Keep Docker Desktop running before continuing.

4. (Recommended) Install the [Visual Studio Code WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) extension in VS Code (or a VS Code–based editor).

5. In PowerShell, clone the repo and `cd` into it:

   ```powershell
   git clone https://github.com/opencourtsfyi/opencourts-ckan.git
   cd opencourts-ckan
   ```

6. From that same PowerShell window, open the project in WSL (for example, if using VS Code):

   ```powershell
   wsl code .
   ```

7. In the editor, open **Terminal → New Terminal** and verify Docker:

   ```bash
   docker version
   ```

8. Install [uv](https://docs.astral.sh/uv/getting-started/installation/) and ensure it is on your PATH. From the repo root:

   ```bash
   uv venv --python ">=3.12"
   ```

##### Notes

* Run all [common commands](#common-commands) from the WSL terminal only. PowerShell and CMD are not supported for this repo’s `bin/` scripts.
* See [Troubleshooting → Windows (WSL2)](docs/TROUBLESHOOTING.md#windows-wsl2) for slow Docker builds on `/mnt/c/...` and other WSL2 issues.

### Setup

**NOTE**: this setup guide assumes you are running the solution in [ckan-docker development mode](https://github.com/ckan/ckan-docker?tab=readme-ov-file#development-mode). (See [updating the environment file for development mode](https://github.com/ckan/ckan-docker?tab=readme-ov-file#updating-the-environment-file-for-development-mode) for more information).

#### Steps

| Step | Description | Command/Action |
| --- | --- | --- |
| 1 | Copy the environment template | `cp .env.example .env` |
| 2 | Build the Docker containers | `bin/compose build` |
| 3 | Start Docker Compose | `bin/compose up` |
| 4 | Wait until CKAN is healthy | `curl -s http://localhost:5000/api/action/status_show` returns `"success": true` |
| 5 | Visit the local CKAN site | Open [http://localhost:5000/](http://localhost:5000/) in a browser |
| 6 | Log in with the default admin credentials | `ckan_admin` / `test1234` |
| 7 | (Optional) Explore catalogue APIs | See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — seed test data first ([Seeding Data](#seeding-data)) |

> **NOTE**: to run locally using HTTPS, see [Running with HTTPS](#running-with-https). Keep `CKAN_SITE_URL` in `.env` aligned with your HTTP/HTTPS choice; it affects catalogue and download URLs (see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)).

### Common commands
| Task | Command |
| --- | --- |
| Build containers | `bin/compose build` |
| Start stack | `bin/compose up` |
| Stop stack | `bin/compose down` |
| Stop and remove volumes (reset local data) | `bin/compose down -v` — see [Troubleshooting](docs/TROUBLESHOOTING.md#resetting-volumes-and-stale-local-state) |
| CKAN CLI | `./bin/ckan …` |
| Seed test data | `uv run scripts/seed.py "$CKAN_API_TOKEN"` |
| Catalogue smoke test | `uv run scripts/verify_catalog.py` |
| Check CKAN is up | `curl -s http://localhost:5000/api/action/status_show` |

#### Notes
If you change `CKAN_PORT_HOST` in `.env`, update `CKAN_SITE_URL` to match and recreate containers. Port conflicts: [Troubleshooting → Port already in use](docs/TROUBLESHOOTING.md#port-already-in-use).
The `bin/compose` and `bin/ckan` wrappers are described in [ckan-docker development mode](https://github.com/ckan/ckan-docker?tab=readme-ov-file#development-mode).

### Seeding Data

The development environment can be seeded with test data. A small sample of the [Datasets - Measures for Justice](https://app.measuresforjustice.org/portal/datasets) for NC has been added to this project. To set this up:

```sh
# create an API token
export CKAN_API_TOKEN="$(./bin/ckan user token add ckan_admin my-test-token | tail -1 | tr -d '[:space:]')"

# seed your database
uv run scripts/seed.py "$CKAN_API_TOKEN"

# Desired console output:
# Seeding CKAN at http://localhost:5000...
# Action 'organization_create' reported conflict for 'test-org' (already exists).
# Action 'package_create' reported conflict for 'test-package' (already exists).
# Action 'resource_create' succeeded for 'Test Data Measures For Justice: NC 2013'
# Action 'resource_create' succeeded for 'Test Data Measures For Justice: NC locations'
# Action 'resource_create' succeeded for 'Test Data Measures For Justice: NC measures'
# Action 'resource_create' succeeded for 'Test Data Measures For Justice: NC filters'
```

Once you've executed this script you should see a test organization, and datasets on your local development site. The seeded `test-org` and `test-package` datasets are used in the [catalogue API examples](docs/ARCHITECTURE.md#ckan-action-api) in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

### Verifying catalogue access

After seeding, run the catalogue smoke script (anonymous read checks — no API token):

```sh
uv run scripts/verify_catalog.py
```

Wait until CKAN is healthy (`curl http://localhost:5000/api/action/status_show`) before running, especially right after `bin/compose up`. If checks fail, see [Troubleshooting → CKAN not ready yet](docs/TROUBLESHOOTING.md#ckan-not-ready-yet).

> **CI**: Non-draft pull requests to `main`, pushes to `main`, and manual [workflow_dispatch](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-workflow-runs/manually-running-a-workflow) runs execute the [Catalog smoke test](.github/workflows/catalog-smoke.yml) workflow. It brings up the dev stack, seeds data with `scripts/seed.py`, and runs `scripts/verify_catalog.py` — the same checks as above. Draft PRs skip the smoke test to save CI time; mark ready for review or run the workflow manually to trigger it.

> **NOTE**: This is a minimal smoke script, not a full test suite. Broader local test infrastructure is tracked in [opencourts-infra#17](https://github.com/opencourtsfyi/opencourts-infra/issues/17) / [#23](https://github.com/opencourtsfyi/opencourts-infra/issues/23). See [docs/ARCHITECTURE.md § Local verification workflow](docs/ARCHITECTURE.md#local-verification-workflow).

### Teardown

To remove all Docker resources you have created (for example: containers, volumes):

```sh
bin/compose down -v
```

When to reset volumes and what gets removed: see [Troubleshooting → Resetting volumes](docs/TROUBLESHOOTING.md#resetting-volumes-and-stale-local-state).

### Remote debugging

1. Set `USE_DEBUGPY_FOR_DEV=true` in `.env` (see [ckan-docker — Remote debugging](https://github.com/ckan/ckan-docker?tab=readme-ov-file#remote-debugging-with-vs-code)).
2. Install extensions and start the stack:

```sh
bin/install_src
bin/compose up
```

3. Attach your editor — follow the [ckan-docker VS Code attach steps](https://github.com/ckan/ckan-docker?tab=readme-ov-file#remote-debugging-with-vs-code).

> **NOTE:** the containers also support [debugging with pdb](https://github.com/ckan/ckan-docker?tab=readme-ov-file#6-debugging-with-pdb).

### Running with HTTPS

For dev HTTPS (`USE_HTTPS_FOR_DEV`, self-signed cert on port 5000), follow [ckan-docker — Running HTTPS on development mode](https://github.com/ckan/ckan-docker?tab=readme-ov-file#running-https-on-development-mode), then recreate containers:

```sh
bin/compose down && bin/compose up
```

Keep `CKAN_SITE_URL` aligned with how you reach CKAN — it affects [catalogue and download URLs](docs/ARCHITECTURE.md).

To test the **production-style nginx stack** (HTTPS on port 8443) instead, use `docker-compose.yml` rather than `bin/compose`. See [ckan-docker § NGINX](https://github.com/ckan/ckan-docker?tab=readme-ov-file#8-nginx) and set in `.env`:

```sh
USE_HTTPS_FOR_DEV=false
CKAN_SITE_URL=https://localhost:8443
CKAN__DATAPUSHER__CALLBACK_URL_BASE=http://ckan:5000
```

```sh
docker compose -f docker-compose.yml up
```

Then visit [https://localhost:8443](https://localhost:8443).

## Tracking ckan-docker upstream

This repo uses a subset of [ckan/ckan-docker](https://github.com/ckan/ckan-docker). To pull in upstream changes when upgrading CKAN versions:

```sh
# Set up a remote to track changes:
git remote add ckan-docker https://github.com/ckan/ckan-docker.git
git fetch ckan-docker --no-tags

# Review upstream changes:
git log HEAD..ckan-docker/master --oneline

# To selectively apply upstream changes
git merge --squash ckan-docker/master
# undo any changes we are definitely managing ourselves (currently just the readme):
git checkout HEAD -- README.md

# commit the changes, and track the SHA of the upstream commit we merged:
SHA=$(git rev-parse --short ckan-docker/master)
git commit -m "Merged upstream ckan-docker up to SHA: <$SHA>"
git tag -a ckan-docker-$SHA -m "Merged upstream ckan-docker up to SHA: <$SHA>"
```
