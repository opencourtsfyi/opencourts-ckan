# opencourts-ckan

The metadata, pipelines, extensions for the CKAN portion of open courts

## Table of contents

- [Development](#development)
  - [Prerequisites](#prerequisites)
  - [Setup](#setup)
  - [Seeding Data](#seeding-data)
  - [Teardown](#teardown)
  - [Remote debugging](#remote-debugging)
  - [OSX](#osx)
  - [Running with HTTPS](#running-with-https)
- [Tracking ckan-docker upstream](#tracking-ckan-docker-upstream)

## Development

This project is a copy of the [ckan/ckan-docker](https://github.com/ckan/ckan-docker) repository. For more information on local development, see the [ckan-docker development mode instructions](https://github.com/ckan/ckan-docker?tab=readme-ov-file#development-mode).

### Prerequisites

- A Unix-like development environment for running Docker and the project's shell scripts (examples: Linux, macOS, or Windows with [WSL](https://learn.microsoft.com/en-us/windows/wsl/))
- [Docker](https://www.docker.com) is installed
- [uv](https://github.com/astral-sh/uv) is installed

### Setup

This project uses Docker and Docker Compose. To get started:

| Step | Description | Command/Action |
| --- | --- | --- |
| 1 | Copy the environment template | `cp .env.example .env` |
| 2 | Build the Docker containers | `bin/compose build` |
| 3 | Start Docker Compose | `bin/compose up` |
| 4 | Visit the local CKAN site | Open [http://localhost:5000/](http://localhost:5000/) in a browser |
| 5 | Log in with the default admin credentials | `ckan_admin` / `test1234` |

> **NOTE**: to run locally using HTTPS, see [Running with HTTPS](#running-with-https).

### Seeding Data

The development environment can be seeded with test data. A small sample of the [Datasets - Measures for Justice](https://app.measuresforjustice.org/portal/datasets) for NC has been added to this project. To set this up:

```sh
# create an API token
export CKAN_API_TOKEN="$(./bin/ckan user token add ckan_admin my-test-token | tail -1 | tr -d '[:space:]')"

# seed your database
uv run scripts/seed.py "$CKAN_API_TOKEN"

# Seeding CKAN at http://localhost:5000...
# Action 'organization_create' reported conflict for 'test-org' (already exists).
# Action 'package_create' reported conflict for 'test-package' (already exists).
# Action 'resource_create' succeeded for 'Test Data Measures For Justice: NC 2013'
# Action 'resource_create' succeeded for 'Test Data Measures For Justice: NC locations'
# Action 'resource_create' succeeded for 'Test Data Measures For Justice: NC measures'
# Action 'resource_create' succeeded for 'Test Data Measures For Justice: NC filters'
```

Once you've executed this script you should see a test organization, and datasets on your local development site.

### Teardown

To remove all Docker resources you have created (for example: containers, volumes):

```sh
./bin/compose down -v
```

### Remote debugging

To enable remote debugging with VS Code:
- Enable debugging support in your `.env` file
- Run this project in development mode.
- Set up VS Code to attach to a running Docker container.

Then install the source and run your containers:

```sh
bin/install_src
bin/compose up
```

Then setup VS Code to debug your instance: [ckan/ckan-docker](https://github.com/ckan/ckan-docker?tab=readme-ov-file#remote-debugging-with-vs-code).


> **NOTE**: the containers also support [debugging with pdb](https://github.com/ckan/ckan-docker?tab=readme-ov-file#6-debugging-with-pdb), if you prefer this.

### OSX

#### Apple Silicon

The base images are only built for the amd64 architecture, so you will need to run Docker in emulation mode. To do this, set the following environment variable in your terminal before running the above commands:

```sh
export DOCKER_DEFAULT_PLATFORM=linux/amd64

docker ...
```

> **NOTE**: if you see errors like "failed to solve: ckan/ckan-dev:2.11: failed to resolve source metadata for docker.io/ckan/ckan-dev", it's likely you are running on Apple Silicon and forgot to set the `DOCKER_DEFAULT_PLATFORM` environment variable.

#### Port 5000 conflict

Later versions of OSX support "AirPlay Receiver" which uses port 5000 which conflicts with the default CKAN port. You have two choices:

- Turn off AirPlay Receiver in System Preferences -> Sharing -> AirDrop & Handoff -> AirPlay Receiver
- Change the CKAN port by setting the `CKAN_PORT_HOST` environment variable in your `.env` file to something other than 5000 (e.g. 5001)

### Running with HTTPS

The default dev setup serves CKAN over HTTP on port 5000. To test over HTTPS locally, update these settings in `.env`:

```sh
USE_HTTPS_FOR_DEV=true
CKAN_SITE_URL=https://localhost:5000
```

Recreate the containers so the changes take effect:

```sh
bin/compose down && bin/compose up
```

Then visit [https://localhost:5000](https://localhost:5000). Your browser will warn about the self-signed certificate — that is expected for local development.

To test the production-style nginx stack instead (HTTPS on port 8443), use `docker-compose.yml` rather than `bin/compose`, and set:

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
