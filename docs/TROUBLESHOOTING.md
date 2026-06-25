# Troubleshooting

Common problems when running the local CKAN dev stack. For setup and day-to-day
commands, see [README.md](../README.md).

## Table of contents

- [All platforms](#all-platforms)
  - [Port already in use](#port-already-in-use)
  - [CKAN not ready yet](#ckan-not-ready-yet)
  - [Resetting volumes and stale local state](#resetting-volumes-and-stale-local-state)
- [macOS](#macos)
  - [Apple Silicon Macs (M1 and later)](#apple-silicon-macs-m1-and-later)
  - [Port 5000 conflict (AirPlay Receiver)](#port-5000-conflict-airplay-receiver)
- [Windows (WSL2)](#windows-wsl2)
- [Linux](#linux)
- [Related topics](#related-topics)
- [Still stuck?](#still-stuck)

## All platforms

### Port already in use

**Symptom:** `bin/compose up` fails, CKAN does not respond on [http://localhost:5000](http://localhost:5000), or Docker reports a port bind error.

**Likely cause:** Another process is using the host port mapped to CKAN (default `5000` via `CKAN_PORT_HOST` in `.env`).

**Fix:**

1. Find what is using the port (replace `5000` if you changed `CKAN_PORT_HOST`):

   ```sh
   # Linux / WSL / macOS
   ss -tlnp | grep ':5000' || lsof -i :5000
   ```

2. Stop that process, **or** change the CKAN host port in `.env`:

   ```sh
   CKAN_PORT_HOST=5001
   CKAN_SITE_URL=http://localhost:5001
   ```

3. Recreate containers so the new port and URL take effect:

   ```sh
   bin/compose down && bin/compose up
   ```

`CKAN_SITE_URL` must match how you reach CKAN in the browser — it affects catalogue links and seeded resource URLs (see [docs/ARCHITECTURE.md](ARCHITECTURE.md)).

On **macOS**, port 5000 is often taken by AirPlay Receiver — see [Port 5000 conflict (AirPlay Receiver)](#port-5000-conflict-airplay-receiver) below.

### CKAN not ready yet

**Symptom:** `curl http://localhost:5000/api/action/status_show` fails, the CKAN site does not load, or `uv run scripts/verify_catalog.py` errors immediately after `bin/compose up`.

**Likely cause:** Containers are still starting. CKAN, Postgres, and Solr all have health checks; the first boot after a build can take several minutes.

**Fix:**

1. Wait and retry:

   ```sh
   curl -s http://localhost:5000/api/action/status_show
   ```

   A healthy CKAN returns JSON with `"success": true`.

2. Check container status:

   ```sh
   bin/compose ps
   ```

   Services should show `healthy` (or `running` while health checks are in progress).

3. If a service stays unhealthy, inspect logs:

   ```sh
   bin/compose logs ckan-dev
   bin/compose logs db
   bin/compose logs solr
   ```

4. After changing `.env`, recreate containers: `bin/compose down && bin/compose up`.

See [README § Verifying catalogue access](../README.md#verifying-catalogue-access) once CKAN is up.

### Resetting volumes and stale local state

**Symptom:** Wrong or old data after schema changes, a bad seed run, Solr search returning nothing, or you want a clean slate.

**Likely cause:** Named Docker volumes from a previous run still hold Postgres, Solr, or CKAN data.

**Fix:** Stop the stack and remove containers **and** volumes:

```sh
bin/compose down -v
```

This removes the dev-mode named volumes defined in `docker-compose.dev.yml`:

| Volume | Holds |
|--------|--------|
| `pg_data` | PostgreSQL database |
| `solr_data` | Solr search index |
| `ckan_storage` | CKAN file storage |
| `pip_cache`, `site_packages`, `local_bin`, `home_dir` | Dev container caches and installed packages |

**When to use:** corrupted DB, need to re-run migrations from scratch, Solr index out of sync, or after major `.env` / image changes that are easier to fix with a clean volume set.

**After reset:** Run the [README setup steps](../README.md#setup) again (`bin/compose build`, `bin/compose up`, wait for health), then [seed](../README.md#seeding-data) and [verify](../README.md#verifying-catalogue-access) if needed.

`bin/compose down` without `-v` stops containers but **keeps** volumes — use that when you only need to restart, not wipe data.

## macOS

### Apple Silicon Macs (M1 and later)

CKAN’s base images are built for `amd64` (Intel/x86_64). Apple Silicon Macs use `arm64`, so Docker must emulate `amd64`. **Intel Macs** use `amd64` natively and can skip this section. See also [Docker multi-platform builds](https://docs.docker.com/build/building/multi-platform/).

Set this in your terminal **before** `bin/compose build` / `bin/compose up`:

```sh
export DOCKER_DEFAULT_PLATFORM=linux/amd64
```

> **NOTE:** If you see errors like `failed to solve: ckan/ckan-dev:2.11: failed to resolve source metadata for docker.io/ckan/ckan-dev`, you are likely on an Apple Silicon Mac and forgot to set `DOCKER_DEFAULT_PLATFORM`.

### Port 5000 conflict (AirPlay Receiver)

Recent macOS versions enable **AirPlay Receiver**, which listens on port 5000 and conflicts with the default CKAN port. Either:

- Turn off AirPlay Receiver: **System Settings → General → AirDrop & Handoff → AirPlay Receiver** (on older macOS: **System Preferences → Sharing → AirDrop & Handoff**)
- Change the host port: set `CKAN_PORT_HOST` in `.env` to something other than `5000` (e.g. `5001`), update `CKAN_SITE_URL` to match (e.g. `http://localhost:5001`), then `bin/compose down && bin/compose up`

See also [Port already in use](#port-already-in-use) for generic port diagnostics.

## Windows (WSL2)

This repo’s shell scripts (`bin/compose`, `bin/ckan`, etc.) expect a Unix-like environment. Use **WSL2**, not PowerShell or CMD alone.

To open a terminal:
- Launch the Ubuntu app from the Start menu, or
- Open Windows Terminal and choose the Ubuntu profile, or
- In VS Code use Remote WSL / `code .` from a WSL shell.

Docker Desktop setup is covered in [Docker’s WSL guide](https://docs.docker.com/desktop/features/wsl/).

| Symptom | Likely cause | Fix |
|--------|--------------|-----|
| Poor editor integration / WSL performance | Editor opened without Visual Studio Code WSL extension | Install/enable the [Visual Studio Code WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) extension, which improves performance when working with files in the WSL environment. |
| `code` or `cursor`: command not found in WSL | Editor shell command not installed in WSL | Run **Shell Command: Install 'code' command in PATH** from the editor’s Command Palette (once), then retry `wsl code .` or `wsl cursor .` |
| Slow builds, permission errors, or bind-mount failures | Repo cloned under `/mnt/c/...` | Clone and work under the Linux filesystem, e.g. `~/dev/opencourts-ckan` |
| `docker: command not found` in WSL | Docker not integrated with your distro | Install [Docker Desktop](https://www.docker.com/products/docker-desktop/), enable the WSL 2 backend, and turn on **Settings → Resources → WSL integration** for your distro |
| `permission denied` connecting to Docker | Docker Desktop socket access blocked or WSL user not in `docker` group | Ensure Docker Desktop is running and Ubuntu integration is enabled, then run `sudo usermod -aG docker "$USER"` in WSL, `exec bash`, and from PowerShell `wsl --shutdown` before reopening Ubuntu |
| Editor can’t find files or terminals behave oddly | Project opened via Windows path instead of WSL | In Cursor or VS Code, open the folder **from WSL** (Remote WSL / `cursor .` from a WSL shell in the repo root), not `C:\...` pointing at WSL files |
| Containers exit unexpectedly or builds fail with memory errors | Default WSL/Docker memory too low for this stack | Raise **Docker Desktop → Settings → Resources** limits and/or set `memory=8GB` (or higher) in [`%USERPROFILE%\.wslconfig`](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#configure-global-options-with-wslconfig), then run `wsl --shutdown` and restart WSL |
| Port bind errors despite nothing obvious on Windows | Another WSL service or prior container | From WSL: `ss -tlnp | grep ':5000'`; run `bin/compose down` before changing ports |

The `./src` bind mount in dev mode must live on a path Docker can mount efficiently — keep the repo on the WSL filesystem, not under `/mnt/c/`.

For general Docker Compose behaviour (logs, rebuilding, extension mounts), see [ckan-docker development mode](https://github.com/ckan/ckan-docker?tab=readme-ov-file#development-mode).

## Linux

| Symptom | Likely cause | Fix |
|--------|--------------|-----|
| `permission denied` connecting to Docker | User not in `docker` group | Add your user to the `docker` group and re-login, or use `sudo` (see [Docker Engine install](https://docs.docker.com/engine/install/)) |
| Port already in use | Another local service on `5000` | [Port already in use](#port-already-in-use) |

## Related topics

| Topic | Where to look |
|-------|----------------|
| HTTPS / self-signed certificate warnings | [README § Running with HTTPS](../README.md#running-with-https) and [ckan-docker — Running HTTPS on development mode](https://github.com/ckan/ckan-docker?tab=readme-ov-file#running-https-on-development-mode) |
| Remote debugging (VS Code / Cursor) | [README § Remote debugging](../README.md#remote-debugging) |
| Upstream image or compose changes | [README § Tracking ckan-docker upstream](../README.md#tracking-ckan-docker-upstream) |
| Catalogue / API smoke checks | [docs/ARCHITECTURE.md § Local verification workflow](ARCHITECTURE.md#local-verification-workflow) |

## Still stuck?

1. Capture output from `bin/compose ps` and `bin/compose logs ckan-dev` (last 50 lines).
2. Check [ckan-docker development mode](https://github.com/ckan/ckan-docker?tab=readme-ov-file#development-mode) for generic CKAN-on-Docker issues.
3. Open an issue in [opencourts-ckan](https://github.com/opencourtsfyi/opencourts-ckan/issues) with your OS, Docker version (`docker version`), and the logs above.
