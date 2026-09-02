#!/usr/bin/env bash
# Fast-forward this fork to its upstream without user interaction.
#
# Triggered by the SessionStart hook in ../settings.json on every droid
# session, and by .github/workflows/upstream-sync.yml on a schedule — one
# implementation, two triggers.
#
# Fast-forward only. A diverged local branch is a contingency, never bypassed:
# the script stops loudly and the caller alerts instead of rewriting history.

set -euo pipefail

PROJECT_DIR="${FACTORY_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
cd "$PROJECT_DIR"

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-master}"
LOCAL_BRANCH="${LOCAL_BRANCH:-master}"

git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1 || {
  # Empty catch: a missing upstream remote is the loud misconfiguration the
  # settings layer must surface; the sync cannot proceed past it, so this
  # swallows nothing — it exits with the reason on stderr.
  echo "upstream-sync: no '$UPSTREAM_REMOTE' remote configured — refusing to guess" >&2
  exit 2
}

git fetch --prune "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"

# Fast-forward only: ancestor check, then move the LOCAL branch with
# --ff-only before pushing it. The local checkout is never bypassed — pushing
# a remote-tracking ref straight to origin would leave this working tree
# behind, which is exactly the divergence this script exists to prevent.
if git merge-base --is-ancestor "$LOCAL_BRANCH" "refs/remotes/$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"; then
  git merge --ff-only "refs/remotes/$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
  git push origin "refs/heads/$LOCAL_BRANCH"
  echo "upstream-sync: $LOCAL_BRANCH fast-forwarded to $UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
else
  echo "upstream-sync: '$LOCAL_BRANCH' diverged from $UPSTREAM_REMOTE/$UPSTREAM_BRANCH — leaving it untouched" >&2
  echo "upstream-sync: contingency: merge upstream/$UPSTREAM_BRANCH manually or re-clone; this script never rewrites history" >&2
  exit 3
fi
