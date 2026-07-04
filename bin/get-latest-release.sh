#!/usr/bin/env bash
# Overwrites this working copy with the latest version on GitHub.
# WARNING: discards ALL local changes and untracked files — the online
# version wins. No archives are downloaded; it syncs the repo in place.
#
# Usage: bin/get-latest-release.sh
set -e

cd "$(dirname "$0")/.."

git fetch origin --tags --prune --force

git reset --hard origin/main
git clean -fd

echo "Local directory now matches origin/main ($(git log -1 --format='%h %s'))"
