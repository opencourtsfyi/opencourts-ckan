# Cross-platform dev stack verification

Maintained checklist for [opencourts-infra#25](https://github.com/opencourtsfyi/opencourts-infra/issues/25): validate that the local dev stack works on **Linux**, **macOS**, and **Windows (WSL2)**.

Setup instructions live in [README.md](../README.md). Platform-specific fixes: [TROUBLESHOOTING.md](TROUBLESHOOTING.md) when present ([opencourts-ckan#55](https://github.com/opencourtsfyi/opencourts-ckan/pull/55)); otherwise README [Prerequisites](../README.md#prerequisites) and [OSX](../README.md#osx).

This document is the **test protocol and sign-off log** — not a second setup guide.

## Table of contents

- [Validation strategy](#validation-strategy)
- [Verification](#verification)
  - [Manual](#manual)
  - [Script](#script)
- [OS-specific caveats](#os-specific-caveats)
- [Sign-off log](#sign-off-log)
- [Future automation](#future-automation)

## Validation strategy

| OS family | How we validate | Why |
|-----------|-----------------|-----|
| **Linux** | Automated — [Catalog smoke test](../.github/workflows/catalog-smoke.yml) on `ubuntu-latest` for every non-draft PR to `main` | Same sequence as this checklist; runs on every merge |
| **macOS** | Manual sign-off using the steps below | Docker Desktop + Apple Silicon behaviour is not reproduced reliably on GitHub-hosted runners |
| **Windows** | Manual sign-off in **WSL2** using the steps below | Documented contributor path is Ubuntu/WSL + bash `bin/` scripts, not native PowerShell/CMD |

Full cross-OS automation (self-hosted runners, scheduled doc-as-tests, cloud Mac) is **deferred** — see [Future automation](#future-automation).

Re-run the manual checklist when compose files, Dockerfiles, seed scripts, or `verify_catalog.py` change in ways that could affect local startup.

## Verification

### Manual

Run each step manually from the **repository root** in a bash shell OR run the [verification script](#script) below.

> **NOTE**: this sequence matches the [`catalog-smoke.yml`](../.github/workflows/catalog-smoke.yml) workflow in CI.

| Step | Command / action | Pass criteria |
|------|------------------|---------------|
| 1. Setup | `cp .env.example .env` | `.env` present |
| 2. Compose up | `bin/compose build && bin/compose up -d` | All services start; no build errors |
| 3. Ready | `curl -fsS http://localhost:5000/api/action/status_show` | HTTP 200 (retry until healthy — CKAN first boot can take several minutes) |
| 4. Seed | Create sysadmin API token, then `uv run scripts/seed.py "$CKAN_API_TOKEN"` | Seed completes without error (409 "already exists" is OK on re-runs) |
| 5. Smoke test | `uv run scripts/verify_catalog.py` | Exit code 0 |
| 6. Compose down | `bin/compose down -v` | Containers removed; named volumes cleared |

### Script

#### macOS Apple Silicon users only
Set the platform before running:
>
> ```sh
> export DOCKER_DEFAULT_PLATFORM=linux/amd64
> ```

#### All users
From the repository root, run:

```sh
./scripts/verify_dev_stack.sh
```

This script runs all six checklist steps in order, prints `PASS:` / `FAIL:` for each step, and ends with a clear **verification passed** or **verification failed** summary. It exits 0 on success and non-zero on failure (same as CI).

## OS-specific caveats

Read these **before** step 2. Details and fixes are in [TROUBLESHOOTING.md](TROUBLESHOOTING.md) (or README until #55 merges).

| OS | Before you run | Common blockers |
|----|----------------|-----------------|
| **Linux** | Docker Engine or Docker CE with Compose plugin; [uv](https://docs.astral.sh/uv/) installed | Port 5000 in use (`ss -tlnp \| grep ':5000'`); user not in `docker` group |
| **macOS** | Docker Desktop for Mac; `uv` installed | **Apple Silicon:** `export DOCKER_DEFAULT_PLATFORM=linux/amd64` before build; AirPlay Receiver on port 5000 |
| **Windows (WSL2)** | WSL2 + Ubuntu; Docker Desktop with WSL integration; repo cloned under `/home/...`, **not** `/mnt/c/...` | Running from PowerShell/CMD instead of WSL; Docker socket permissions; opening project via `C:\...` instead of Remote WSL |

| Topic | Where to look |
|-------|----------------|
| Port conflicts | [TROUBLESHOOTING → Port already in use](TROUBLESHOOTING.md#port-already-in-use) |
| macOS / Apple Silicon | [TROUBLESHOOTING → macOS](TROUBLESHOOTING.md#macos) |
| Windows / WSL2 | [README → Prerequisites](../README.md#prerequisites) (see [TROUBLESHOOTING → Windows (WSL2)](TROUBLESHOOTING.md#windows-wsl2) when available) |
| CKAN not ready yet | [TROUBLESHOOTING → CKAN not ready yet](TROUBLESHOOTING.md#ckan-not-ready-yet) |
| Reset stale state | [TROUBLESHOOTING → Resetting volumes](TROUBLESHOOTING.md#resetting-volumes-and-stale-local-state) |
| What the smoke script checks | [ARCHITECTURE → Local verification workflow](ARCHITECTURE.md#local-verification-workflow) |

## Sign-off log

Update this table when a maintainer completes a manual run or when CI behaviour changes.

| OS | Last verified | Verified by | Environment | Up | Seed | Smoke | Down | Notes |
|----|---------------|-------------|-------------|:--:|:----:|:-----:|:----:|-------|
| Linux | *(automated)* | [`catalog-smoke.yml`](../.github/workflows/catalog-smoke.yml) | GitHub `ubuntu-latest` | ✅ | ✅ | ✅ | ✅ | Every non-draft PR to `main` |
| Windows (WSL2) | 2026-06-25 | @jtasse | WSL2 + Docker Desktop; VS Code and Cursor | ✅ | ✅ | ✅ | ✅ | Validated while creating this document ([opencourts-infra#25](https://github.com/opencourtsfyi/opencourts-infra/issues/25)) |
| macOS | — | — | — | — | — | — | — | **Pending** — no Mac hardware available for this PR; track in a follow-up or volunteer sign-off |

## Future automation

Possible follow-ups (not required to close [opencourts-infra#25](https://github.com/opencourtsfyi/opencourts-infra/issues/25)):

- [Docs as Tests](https://www.docsastests.com/) runner that executes README setup commands in CI
- Self-hosted macOS / WSL2 GitHub Actions runners
