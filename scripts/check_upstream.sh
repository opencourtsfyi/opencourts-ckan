#!/usr/bin/env bash
set -euo pipefail

emit_github_warning() {
  local title="$1"
  local message="$2"

  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    local warning_msg="${message//'%'/'%25'}"
    warning_msg="${warning_msg//$'\r'/'%0D'}"
    warning_msg="${warning_msg//$'\n'/'%0A'}"
    echo "::warning title=${title}::${warning_msg}"
  fi
}

if ! git remote | grep -q '^ckan-docker$'; then
  git remote add ckan-docker https://github.com/ckan/ckan-docker.git
fi

if ! git fetch ckan-docker --no-tags --quiet; then
  echo "error: failed to fetch ckan-docker remote" >&2
  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    echo "::error title=Upstream ckan-docker::Failed to fetch https://github.com/ckan/ckan-docker.git"
  fi
  exit 1
fi

LAST_TAG=$(git tag --list 'ckan-docker-*' --sort=-creatordate | head -1)

if [ -z "$LAST_TAG" ]; then
  NO_TAG_MSG="No ckan-docker-* merge tag found. See README (Tracking ckan-docker upstream) to record the last upstream merge."
  echo "⚠️  $NO_TAG_MSG"
  emit_github_warning "Upstream ckan-docker" "$NO_TAG_MSG"
  exit 0
fi

LAST_MERGED_SHA=${LAST_TAG#ckan-docker-}

if ! git rev-parse --verify "${LAST_MERGED_SHA}^{commit}" >/dev/null 2>&1; then
  BAD_TAG_MSG="Merge tag ${LAST_TAG} points to unknown commit ${LAST_MERGED_SHA}."
  echo "⚠️  $BAD_TAG_MSG" >&2
  emit_github_warning "Upstream ckan-docker" "$BAD_TAG_MSG"
  exit 0
fi

CHANGES=$(git log "${LAST_MERGED_SHA}"..ckan-docker/master --oneline)

if [ -n "$CHANGES" ]; then
  echo "⚠️  Upstream ckan-docker has unmerged changes since $LAST_TAG:"
  echo "$CHANGES"
  emit_github_warning "Upstream ckan-docker" "$(printf 'Unmerged upstream changes since %s:\n%s' "$LAST_TAG" "$CHANGES")"
fi
