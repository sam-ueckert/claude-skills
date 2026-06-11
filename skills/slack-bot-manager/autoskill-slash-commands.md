# Autoskill: Slack Slash Command Ownership

## MANDATORY: Check Before Adding Any Slash Command

Slack slash commands are **workspace-global** — only one app can own a given command name.
Pushing a conflicting command via `apps.manifest.update` will succeed at the API level
but will **break** the conflicting app's command silently or at reinstall.

## Known Command Owners (as of 2026-06-11)

### Swabby (OpenClaw Slack gateway) — App ID: `A0AM3S8QJQ5`
`/memory` `/model` `/think` `/reset` `/stop` `/help` `/context` `/compact` `/new`
`/archy` `/foreman` `/reasoning` `/verbose` `/elevated` `/fast` `/tools` `/subagents`
`/steer` `/queue` `/goal` `/tts` `/export-session`

### Swabby Ops (ops-bot) — App ID: `A0ARUHGF7GE`
`/restore` `/purge` `/restart-gw` `/clear-warnings` `/mute-warnings` `/janitor`
`/vault-set` `/vault-list` `/vault-delete`

### Swabby Hermes — App ID: `A0B25G3562K`
`/hermes` `/h-sethome` `/h-new` `/h-model` `/h-compress` `/h-resume` `/h-sessions`
`/h-goal` `/h-tools` `/h-skills` `/h-help` `/h-stop` `/h-reasoning` `/h-yolo`
`/h-background` `/h-usage` `/h-config` `/h-verbose`

## Workflow for Adding Hermes Commands

1. Check the command name against all three owner tables above
2. If already owned → use `/h-<name>` prefix for Hermes instead
3. If free → safe to add natively
4. Always `apps.manifest.export` the target app first — never reconstruct from memory
5. Validate before pushing: `apps.manifest.validate`
6. After push: check `permissions_updated` in response
   - `false` → live immediately
   - `true` → new scopes added, app must be reinstalled to activate

## Lesson Learned (2026-06-11)

`hermes slack manifest` generates a 50-command manifest assuming Hermes owns the workspace.
**Do NOT push this manifest directly** — it conflicts with Swabby and Swabby Ops.
Instead, cherry-pick only commands not already owned, using `/h-` prefix for conflicts.
