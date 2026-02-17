# opencourts-ckan
Metadata, pipelines, and extensions for the CKAN portion of Open Courts.

This repository contains a customized CKAN instance using the [ckan-docker](https://github.com/ckan/ckan-docker) submodule with additional extensions.

## Structure

- `ckan-docker/` - Git submodule pointing to the official CKAN Docker repository
- `docker/` - Custom Docker configurations for this project
  - `docker/ckan/Dockerfile.dev` - Custom CKAN development image with extensions
- `schemas/` - CKAN scheming schema definitions
  - `schemas/dataset.json` - Dataset schema
  - `schemas/group.json` - Group schema
  - `schemas/organization.json` - Organization schema
- `docker-compose.dev.override.yml` - Docker Compose overrides for development
- `ckan-docker/.env` - Environment configuration (not tracked in git)

## Installed Extensions

### ckanext-scheming v3.1.0
Allows customization of CKAN dataset, group, and organization schemas via JSON files.

**Enabled plugins:**
- `scheming_datasets` - Custom dataset schemas
- `scheming_groups` - Custom group schemas
- `scheming_organizations` - Custom organization schemas

## Getting Started

### Prerequisites
- Docker Desktop for Windows
- Git

### Initialize Git Submodule

**Important:** Before starting CKAN, ensure the `ckan-docker` submodule is checked out and up to date:

```powershell
# If cloning for the first time
git clone --recurse-submodules <repository-url>

# Or if you already cloned without --recurse-submodules
git submodule update --init --recursive

# To update the submodule to the latest version
git submodule update --remote ckan-docker
```

### Starting the Development Environment

1. **Start CKAN:**
   ```powershell
   docker compose -f ckan-docker/docker-compose.dev.yml -f docker-compose.dev.override.yml up -d
   ```

2. **Access CKAN:**
   - Web interface: http://localhost:5000
   - Default admin credentials:
     - Username: `ckan_admin`
     - Password: `test1234`

3. **View logs:**
   ```powershell
   docker compose -f ckan-docker/docker-compose.dev.yml -f docker-compose.dev.override.yml logs -f ckan-dev
   ```

### Stopping the Environment

```powershell
docker compose -f ckan-docker/docker-compose.dev.yml -f docker-compose.dev.override.yml down
```

### Rebuilding After Changes

If you modify the Dockerfile or dependencies:

```powershell
# Remove volumes to ensure clean rebuild
docker compose -f ckan-docker/docker-compose.dev.yml -f docker-compose.dev.override.yml down -v

# Rebuild and start
docker compose -f ckan-docker/docker-compose.dev.yml -f docker-compose.dev.override.yml up -d --build
```

## Customization

### Modifying Schemas

Edit the JSON files in the `schemas/` directory. Changes will be reflected on CKAN restart:

```powershell
docker compose -f ckan-docker/docker-compose.dev.yml -f docker-compose.dev.override.yml restart ckan-dev
```

### Adding More Extensions

1. Edit [docker/ckan/Dockerfile.dev](docker/ckan/Dockerfile.dev) to add `RUN pip3 install <extension-name>`
2. Add the plugin name to `CKAN__PLUGINS` in `ckan-docker/.env`
3. Rebuild: `docker compose ... up -d --build`

## Architecture

This setup uses a layered approach:
- **Base:** Official `ckan/ckan-dev:2.11` image from Docker Hub
- **Custom layer:** Our [docker/ckan/Dockerfile.dev](docker/ckan/Dockerfile.dev) adds ckanext-scheming
- **Runtime:** Schema files mounted from [schemas/](schemas/) directory
- **Configuration:** Environment variables in `ckan-docker/.env`

The submodule remains clean (no local changes), all customizations are in the parent repo.

## Verification Commands

```powershell
# Check if scheming is installed
docker compose -f ckan-docker/docker-compose.dev.yml -f docker-compose.dev.override.yml exec ckan-dev python3 -c "import ckanext.scheming; print('OK')"

# View enabled plugins
docker compose -f ckan-docker/docker-compose.dev.yml -f docker-compose.dev.override.yml exec ckan-dev sh -c "grep '^ckan.plugins' /srv/app/ckan.ini"

# List schema files
docker compose -f ckan-docker/docker-compose.dev.yml -f docker-compose.dev.override.yml exec ckan-dev ls -la /srv/app/schemas/
```

## Troubleshooting

### Container is unhealthy
The health check can show "unhealthy" for a minute or two during startup. Check logs for errors.

### Extension not loading
1. Verify the plugin is in `CKAN__PLUGINS` in `ckan-docker/.env`
2. Check logs for errors during startup
3. Rebuild with `--no-cache` if needed

### Schema changes not reflecting
Restart the CKAN container after modifying schema files.

## References

- [CKAN Documentation](https://docs.ckan.org/)
- [ckanext-scheming Documentation](https://github.com/ckan/ckanext-scheming)
- [CKAN Docker Documentation](https://github.com/ckan/ckan-docker)
