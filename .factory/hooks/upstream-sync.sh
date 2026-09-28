#!/usr/bin/env bash
# Sync this fork's checkout with its upstream without user interaction.
#
# Runs from the SessionStart hook in ../settings.json on every droid
# session. Pull only: the checkout moves forward, nothing is pushed to any
# remote. Fast-forward when possible; rebase local commits on top of
# upstream when the branches diverged.

set -euo pipefail

PROJECT_DIR="${FACTORY_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
cd "$PROJECT_DIR"

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-master}"
LOCAL_BRANCH="${LOCAL_BRANCH:-master}"

git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1 || {
  # Missing upstream remote: exit 2 with the reason instead of guessing a URL.
  echo "upstream-sync: no '$UPSTREAM_REMOTE' remote configured — refusing to guess" >&2
  exit 2
}

if [ "$(git symbolic-ref --quiet --short HEAD)" != "$LOCAL_BRANCH" ]; then
  # git merge and git rebase both act on HEAD, so a different checked-out
  # branch must stop the sync rather than move a branch nobody asked about.
  echo "upstream-sync: HEAD is not on '$LOCAL_BRANCH' — leaving the checkout untouched" >&2
  exit 2
fi

git fetch --prune "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"

if git merge-base --is-ancestor "refs/remotes/$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" "$LOCAL_BRANCH"; then
  echo "upstream-sync: $LOCAL_BRANCH already contains $UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
elif git merge-base --is-ancestor "$LOCAL_BRANCH" "refs/remotes/$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"; then
  git merge --ff-only "refs/remotes/$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
  echo "upstream-sync: $LOCAL_BRANCH fast-forwarded to $UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
else
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "upstream-sync: uncommitted changes would be rebased over — commit or stash them first" >&2
    exit 2
  fi
  if ! git rebase "refs/remotes/$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"; then
    # Abort restores the pre-rebase state when a rebase is in progress; a
    # rebase that failed before starting is already in that state.
    git rebase --abort >/dev/null 2>&1 || true
    echo "upstream-sync: rebase onto $UPSTREAM_REMOTE/$UPSTREAM_BRANCH had conflicts — resolve them manually" >&2
    exit 3
  fi
  echo "upstream-sync: $LOCAL_BRANCH rebased onto $UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
fi
