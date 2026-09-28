---
class: process
---

# Scheduled upstream sync

Decided to automate the pull rather than hand-rolling a merge-forward script: a scheduled workflow pushes the fast-forward, the SessionStart hook syncs the local checkout only, and a diverged branch fails loud instead of force-pushing.

## What shipped

- `.factory/settings.json` — project-scope SessionStart hook; runs the sync script on every droid session.
- `.factory/hooks/upstream-sync.sh` — pull only: fast-forward when behind, rebase local commits onto upstream when diverged; it never pushes to a remote.
- `.github/workflows/upstream-sync.yml` — scheduled, unattended trigger; this half pushes the fast-forward to origin.

## What was rejected

- A bot-written merge commit — the fast-forward keeps history linear and the push is the same ref, so nothing rewrites.
- A force-push contingency — a diverged tree stops the run and alerts via issue instead.
