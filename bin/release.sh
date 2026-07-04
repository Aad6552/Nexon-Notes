#!/usr/bin/env bash
# Bumps the app version, commits everything pending, tags the release,
# pushes to GitHub, and publishes a GitHub Release for it (so the in-app
# update checker has a real "latest release" to compare against).
#
# Usage: bin/release.sh [major|minor|patch]   (defaults to patch)
set -e

cd "$(dirname "$0")/.."

command -v gh >/dev/null 2>&1 || { echo "gh (GitHub CLI) is required to publish releases." >&2; exit 1; }

BUMP="${1:-patch}"
VERSION_FILE="VERSION"

[ -f "$VERSION_FILE" ] || echo "1.0.0" > "$VERSION_FILE"

current="$(tr -d '[:space:]' < "$VERSION_FILE")"
IFS='.' read -r major minor patch <<< "$current"

case "$BUMP" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
  *)
    echo "Usage: $0 [major|minor|patch]" >&2
    exit 1
    ;;
esac

new_version="${major}.${minor}.${patch}"
echo "$new_version" > "$VERSION_FILE"

git add -A

if git diff --cached --quiet; then
  echo "Nothing to release — no changes since v${current}."
  exit 0
fi

git commit -m "Release v${new_version}"
git tag "v${new_version}"
git push origin HEAD
git push origin "v${new_version}"

gh release create "v${new_version}" --title "v${new_version}" --generate-notes

echo "Released v${new_version}"
