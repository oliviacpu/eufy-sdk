#!/usr/bin/env bash
# Release the checked-out main: version it <upstream beta version>-oliviacpu.<YYYYMMDD>[.N], pack it,
# tag it oliviacpu-YYYY.MM.DD[.N] and create a GitHub Release with the .tgz attached. Expects a
# verified, built tree (npm run verify has run).
set -euo pipefail

upstream_url=https://github.com/mega-yfue/eufy-sdk.git
base=$(git ls-remote --heads "$upstream_url" 'beta-*' | sed 's#.*refs/heads/beta-##' | sort -V | tail -1)
[ -n "$base" ] || { echo "upstream has no beta-* branch" >&2; exit 1; }

git fetch --quiet --tags origin
day=$(date -u +%Y.%m.%d)
count=$(git tag -l "oliviacpu-$day" "oliviacpu-$day.*" | wc -l | tr -d ' ')
suffix=""
[ "$count" -gt 0 ] && suffix=".$((count + 1))"
tag="oliviacpu-$day$suffix"
version="$base-oliviacpu.$(date -u +%Y%m%d)$suffix"

npm version "$version" --no-git-tag-version >/dev/null
tarball=$(npm pack --silent | tail -1)

git tag "$tag" HEAD
git push origin "$tag"
gh release create "$tag" "$tarball" --title "$tag" --generate-notes \
  --notes "Package \`@mega-yfue/eufy-sdk@$version\`, built from \`main\` at $(git rev-parse --short HEAD)."
echo "released $tag with $tarball"
