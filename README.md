# opencourts-ckan

The metadata, pipelines, extensions for the CKAN portion of open courts.

## Development

This project is a copy of the [ckan/ckan-docker](https://github.com/ckan/ckan-docker) repository. For more information on local development, see the [ckan-docker development mode instructions](https://github.com/ckan/ckan-docker?tab=readme-ov-file#development-mode).

### Prerequisites

Ensure the following packages have been installed on your system:

- Use a *nix compatible system.
- [Docker](https://www.docker.com)
- [uv](https://github.com/astral-sh/uv)

### Setup

This project uses docker and docker compose. To get started:

- Copy the `.env.example` file to `.env`
- Build the docker containers
- Start docker compose
- Visit https://localhost:5000/
- Login with the default credentials (ckan_admin/test1234)

```sh
cp .env.example .env
bin/compose build
bin/compose up

# in a separate terminal:
open https://localhost:5000/
```

### Seeding Data

The development environment can be seeded with test data. A small sample of the [Datasets - Measures for Justice](https://app.measuresforjustice.org/portal/datasets) for NC has been added to this project for the purpose. To set this up:

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

To remove all resources created for development remove all the docker resources (containers, volumes) you have created:

```sh
./bin/compose down -v
```

### Remote debugging

To enable remote debugging with VS Code:
- Enable debugging support in your .env file
- Run this project in development mode.
- Setup VS Code to attache to a running docker container.

Update your .env the following environment variables:

```sh
USE_HTTPS_FOR_DEV=false
CKAN__DATAPUSHER__CALLBACK_URL_BASE=http://ckan-dev:5000
CKAN_SITE_URL=https://localhost:5000
```


Then install the source and run your containers:

```sh
bin/install_src
bin/compose up
```

Then setup VS Code to debug your instance: [ckan/ckan-docker](https://github.com/ckan/ckan-docker?tab=readme-ov-file#remote-debugging-with-vs-code).


Note: the containers also support [debugging with pdb](https://github.com/ckan/ckan-docker?tab=readme-ov-file#6-debugging-with-pdb), if you prefer this.

#### OSX

##### Apple Silicon

The base images are only built for the amd64 architecture, so you will need to run docker in emulation mode. To do this, set the following environment variable in your terminal before running the above commands:

```sh
export DOCKER_DEFAULT_PLATFORM=linux/amd64

docker ...
```

Note: if you see errors like "failed to solve: ckan/ckan-dev:2.11: failed to resolve source metadata for docker.io/ckan/ckan-dev", its likely you are running on Apple Silicon and forgot to set the `DOCKER_DEFAULT_PLATFORM` environment variable.

##### Port 5000 conflict

Later versions of OSX support "AirPlay Receiver" which uses port 5000 which conflicts with the default CKAN port. You have two choices:

- Turn off AirPlay Receiver in System Preferences > Sharing -> AirDrop & Handoff -> AirPlay Receiver
- Change the CKAN port by setting the `CKAN_PORT_HOST` environment variable in your `.env` file to something other than 5000 (e.g. 5001)

## Tracking ckan-docker upstream

This repo uses a subset of [ckan/ckan-docker](https://github.com/ckan/ckan-docker). To pull in upstream changes when upgrading CKAN versions:

```sh
# Setup a remote to track changes:
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

