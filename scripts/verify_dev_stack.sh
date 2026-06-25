#!/usr/bin/env bash
# Cross-platform dev stack verification (opencourts-infra#25).
# Runs compose up → seed → verify_catalog → compose down from the repo root.
# See docs/CROSS_PLATFORM_VERIFICATION.md.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CKAN_URL="${CKAN_URL:-http://localhost:5000/api/action/status_show}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-60}"
SLEEP_SECONDS="${SLEEP_SECONDS:-10}"
TOKEN_NAME="${TOKEN_NAME:-manual-verify-token}"

step_pass() {
  echo "PASS: $*"
}

step_fail() {
  echo "FAIL: $*" >&2
}

on_exit() {
  local status=$?
  echo
  if [ "$status" -eq 0 ]; then
    step_pass "Cross-platform dev stack verification completed successfully."
    echo "All steps passed: setup, compose up, CKAN ready, seed, catalogue smoke test, compose down."
  else
    step_fail "Cross-platform dev stack verification failed (exit code ${status})."
    echo "Review the output above, fix the issue, and re-run: ./scripts/verify_dev_stack.sh" >&2
  fi
  exit "$status"
}

trap on_exit EXIT

if [ ! -x bin/compose ]; then
  step_fail "Run this script from the opencourts-ckan repository root (bin/compose not found)."
  exit 1
fi

echo "=== Cross-platform dev stack verification ==="
echo "Repo: ${ROOT}"
echo

echo "Step 1/6: Setup (.env)"
cp .env.example .env
step_pass "Step 1/6: .env ready"

echo "Step 2/6: Compose build and up"
bin/compose build
bin/compose up -d
step_pass "Step 2/6: Dev stack is up"

echo "Step 3/6: Wait for CKAN"
for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  if curl -fsS "$CKAN_URL" > /dev/null; then
    step_pass "Step 3/6: CKAN ready at ${CKAN_URL} (attempt ${attempt}/${MAX_ATTEMPTS})"
    break
  fi
  if [ "$attempt" -eq "$MAX_ATTEMPTS" ]; then
    step_fail "Step 3/6: CKAN did not become healthy at ${CKAN_URL} within $((MAX_ATTEMPTS * SLEEP_SECONDS)) seconds"
    exit 1
  fi
  echo "Waiting for CKAN... (attempt ${attempt}/${MAX_ATTEMPTS})"
  sleep "$SLEEP_SECONDS"
done

echo "Step 4/6: Seed database"
CKAN_API_TOKEN="$(./bin/ckan user token add ckan_admin "$TOKEN_NAME" | tail -1 | tr -d '[:space:]')"
uv run scripts/seed.py "$CKAN_API_TOKEN"
step_pass "Step 4/6: Database seeded"

echo "Step 5/6: Catalogue smoke test"
echo "Waiting for Solr indexing after seed..."
sleep 10
if uv run scripts/verify_catalog.py; then
  step_pass "Step 5/6: Catalogue smoke test"
else
  echo "First verify attempt failed; retrying once after additional delay..."
  sleep 15
  uv run scripts/verify_catalog.py
  step_pass "Step 5/6: Catalogue smoke test (second attempt)"
fi

echo "Step 6/6: Compose down"
bin/compose down -v
step_pass "Step 6/6: Dev stack torn down"
