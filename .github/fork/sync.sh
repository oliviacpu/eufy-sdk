#!/usr/bin/env bash
# Merge upstream's newest beta-* branch into main, verify, and push. Writes merged=true|false to
# $GITHUB_OUTPUT. On a conflict, a failed verification or a push refused for touching workflow
# files, opens or updates the upstream-sync issue and exits non-zero without pushing.
set -euo pipefail

upstream_url=https://github.com/mega-yfue/eufy-sdk.git
label=upstream-sync
log=$(mktemp)

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git remote add upstream "$upstream_url" 2>/dev/null || git remote set-url upstream "$upstream_url"

branch=$(git ls-remote --heads upstream 'beta-*' | sed 's#.*refs/heads/##' | sort -V | tail -1)
[ -n "$branch" ] || { echo "upstream has no beta-* branch" >&2; exit 1; }
git fetch --quiet upstream "$branch"
sha=$(git rev-parse --short FETCH_HEAD)

if git merge-base --is-ancestor FETCH_HEAD HEAD; then
  echo "main already has upstream $branch ($sha)"
  echo "merged=false" >>"$GITHUB_OUTPUT"
  exit 0
fi

needs_hand() {
  gh label create "$label" --color d93f0b --description "Upstream merge needs a hand" --force >/dev/null
  body=$(printf 'Upstream `%s` at `%s` was not merged: %s.\n\nRun: %s\n\n```\n%s\n```\n' \
    "$branch" "$sha" "$1" "$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID" "$(tail -n 60 "$log")")
  open=$(gh issue list --label "$label" --state open --json number --jq '.[0].number // empty')
  if [ -n "$open" ]; then
    gh issue comment "$open" --body "$body"
  else
    gh issue create --title "Upstream merge needs a hand" --label "$label" --body "$body"
  fi
  exit 1
}

if ! git merge --no-ff --no-edit -m "Merge upstream $branch ($sha)" FETCH_HEAD >"$log" 2>&1; then
  git merge --abort || true
  needs_hand "the merge conflicts"
fi
if git diff --name-only HEAD^1 HEAD | grep -q '^\.github/workflows/'; then
  git diff --name-only HEAD^1 HEAD | grep '^\.github/workflows/' >"$log"
  needs_hand "it changes workflow files, which this workflow's token may not push"
fi
if ! { npm ci && npm run verify; } >"$log" 2>&1; then
  needs_hand "npm run verify fails after the merge"
fi
if ! git push origin HEAD:main >"$log" 2>&1; then
  needs_hand "the push was refused"
fi

echo "merged upstream $branch ($sha)"
echo "merged=true" >>"$GITHUB_OUTPUT"
for n in $(gh issue list --label "$label" --state open --json number --jq '.[].number'); do
  gh issue close "$n" --comment "Upstream $branch ($sha) merged in run $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID."
done
