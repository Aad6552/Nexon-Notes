#!/usr/bin/env bash
# Bumps the app version, commits everything pending, tags the release,
# pushes to GitHub, and publishes a GitHub Release for it (so the in-app
# update checker has a real "latest release" to compare against).
#
# Usage: bin/release.sh [major|minor|patch]   (defaults to patch)
set -e

cd "$(dirname "$0")/.."

command -v gh >/dev/null 2>&1 || { echo "gh (GitHub CLI) is required to publish releases." >&2; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not inside a git repository." >&2; exit 1; }

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

# Roll back the VERSION bump on any failure before the commit lands, so a
# broken release attempt never leaves VERSION pointing at a phantom version
# that was never actually committed or released.
committed=false
rollback() {
  if [ "$committed" = false ]; then
    echo "$current" > "$VERSION_FILE"
  fi
}
trap rollback EXIT

echo "$new_version" > "$VERSION_FILE"
git add -A

if git diff --cached --quiet; then
  echo "Nothing to release — no changes since v${current}."
  exit 0
fi

git commit -m "Release v${new_version}"
committed=true
git push origin HEAD

# Let `gh release create` create the tag itself, pointed at the commit we
# just pushed, so a tag never exists on GitHub without an actual Release
# attached to it (rather than tagging/pushing locally and hoping this step
# also succeeds).
gh release create "v${new_version}" --target "$(git rev-parse HEAD)" \
  --title "v${new_version}" --generate-notes

echo "Released v${new_version}"
