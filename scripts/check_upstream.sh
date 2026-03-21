#!/usr/bin/env bash
set -euo pipefail

if ! git remote | grep -q '^ckan-docker$'; then
  git remote add ckan-docker https://github.com/ckan/ckan-docker.git
fi

git fetch ckan-docker --no-tags --quiet

LAST_TAG=$(git tag --list 'ckan-docker-*' --sort=-creatordate | head -1)
LAST_MERGED_SHA=${LAST_TAG#ckan-docker-}

CHANGES=$(git log "$LAST_MERGED_SHA"..ckan-docker/master --oneline)

if [ -n "$CHANGES" ]; then
  echo "⚠️  Upstream ckan-docker has unmerged changes since $LAST_TAG:"
  echo "$CHANGES"
fi
