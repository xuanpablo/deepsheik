---
class: process
---

# Scheduled upstream sync

Decided to automate the pull rather than hand-rolling a merge-forward script: a scheduled workflow owns it, the SessionStart hook and the cron trigger share one implementation, and a diverged branch fails loud instead of force-pushing.

## What shipped

- `.factory/settings.json` — project-scope SessionStart hook; the script is the single sync implementation.
- `.factory/hooks/upstream-sync.sh` — fast-forward only; divergence never bypasses.
- `.github/workflows/upstream-sync.yml` — scheduled, unattended trigger.

## What was rejected

- A bot-written merge commit — the fast-forward keeps history linear and the push is the same ref, so nothing rewrites.
- A force-push contingency — a diverged tree stops the run and alerts via issue instead.
