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
docker compose build
docker compose up

# in a separate terminal:
open https://localhost:8443/
```

#### OSX on Apple Silicon

The base images are only built for the amd64 architecture, so you will need to run docker in emulation mode. To do this, set the folowing environment variable in your terminal before running the above commands:

```sh
export DOCKER_DEFAULT_PLATFORM=linux/amd64

docker ...
```


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

