# opencourts-ckan

The metadata, pipelines, extensions for the CKAN portion of open courts.

## Development

This project is a copy of the [ckan/ckan-docker](https://github.com/ckan/ckan-docker) repository. For more information on local development, see the [ckan-docker development mode instructions](https://github.com/ckan/ckan-docker?tab=readme-ov-file#development-mode).

### Setup

This project uses docker and docker compose. To get started:

- Copy the `.env.example` file to `.env`
- Build the docker containers
- Start docker compose
- Visit https://localhost:8443/
- Login with the default credentials (ckan_admin/test1234)

```sh
cp .env.example .env
bin/compose build
bin/compose up

# in a separate terminal:
open https://localhost:8443/
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

