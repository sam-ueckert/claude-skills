---
name: slack-bot-manager
description: "Create, modify, or inspect Slack apps and bots via the Manifest API. Use when adding slash commands, updating scopes, changing bot settings, or creating new Slack apps on the swabby workspace."
---

# Slack Bot Manager

Use for any Slack app/bot configuration: slash commands, scopes, interactivity, socket mode, display info.

## Auth: Config Token (MANDATORY FIRST STEP)

All `apps.manifest.*` calls require an `xoxe.xoxp-*` config token — NOT the regular bot or user token.
Config tokens expire every 12 hours and MUST be rotated before use.

```bash
# Step 1: Load stored credentials
CREDS=$(vault cat ~/.openclaw/credentials/slack-xoxp.json.enc)
REFRESH=$(echo "$CREDS" | python3 -c "import json,sys; print(json.load(sys.stdin)['refresh'])")

# Step 2: Rotate to get fresh token
RESULT=$(curl -s https://slack.com/api/tooling.tokens.rotate \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "refresh_token=$REFRESH")
CONFIG_TOKEN=$(echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['token'])")
NEW_REFRESH=$(echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['refresh_token'])")

# Step 3: Save rotated tokens back immediately
python3 -c "import json; json.dump({'xoxp': '$CONFIG_TOKEN', 'refresh': '$NEW_REFRESH'}, open('/tmp/slack-xoxp-new.json','w'))"
vault encrypt /tmp/slack-xoxp-new.json /tmp/slack-xoxp-new.json.enc
cp /tmp/slack-xoxp-new.json.enc ~/.openclaw/credentials/slack-xoxp.json.enc
rm -f /tmp/slack-xoxp-new.json /tmp/slack-xoxp-new.json.enc
```

The config token works for ANY app on the workspace — one token manages all bots.

## Known App IDs

| App | App ID |
|---|---|
| Swabby Ops (ops-bot) | `A0ARUHGF7GE` |

## Common Operations

### Export current manifest
```bash
curl -s https://slack.com/api/apps.manifest.export \
  -H "Authorization: Bearer $CONFIG_TOKEN" \
  -d "app_id=A0ARUHGF7GE" | python3 -m json.tool
```
Always export first before modifying — never reconstruct the manifest from scratch.

### Update manifest (add slash commands, scopes, etc.)
```bash
curl -s https://slack.com/api/apps.manifest.update \
  -H "Authorization: Bearer $CONFIG_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\": \"A0ARUHGF7GE\", \"manifest\": $MANIFEST_JSON}" | python3 -m json.tool
```

### Create a new app
```bash
curl -s https://slack.com/api/apps.manifest.create \
  -H "Authorization: Bearer $CONFIG_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"manifest\": $MANIFEST_JSON}" | python3 -m json.tool
```

### Validate a manifest before pushing
```bash
curl -s https://slack.com/api/apps.manifest.validate \
  -H "Authorization: Bearer $CONFIG_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\": \"A0ARUHGF7GE\", \"manifest\": $MANIFEST_JSON}" | python3 -m json.tool
```

## Manifest Schema Notes

- `slash_commands` live under `features.slash_commands[]` — each needs `command`, `description`, `should_escape`
- Socket mode apps: `settings.socket_mode_enabled: true`, `settings.interactivity.is_enabled: true`
- Bot scopes: `oauth_config.scopes.bot[]`
- `permissions_updated: false` in response = no reinstall needed; `true` = reinstall required

## Workflow

1. Rotate config token (always — even if you think it's fresh)
2. Export current manifest (`apps.manifest.export`)
3. Edit the manifest JSON minimally — patch only what changed
4. Validate (`apps.manifest.validate`) if making complex changes
5. Push (`apps.manifest.update`)
6. Save rotated tokens back to vault
7. Check `ok: true` in response; warn if `permissions_updated: true`

## ops-bot (Swabby Ops)

Source: `~/repos/swabby-brain/plugins/ops-bot/`
Installed as editable: `pip install -e .` — source changes take effect on restart.
Restart: `systemctl --user restart ops-bot` (or `pkill -f ops_bot` + relaunch)
Slash command handlers: `ops_bot/commands/`
Interactive modal handlers: `ops_bot/slack_notifier.py` → `handle_view_submission()`

## Pitfalls

- `unknown_method` on `apps.manifest.*` = you used the wrong token type (xoxb/xoxp won't work — must be `xoxe.xoxp-*`)
- Token expired silently = always rotate via `tooling.tokens.rotate` first, never assume it's valid
- `permissions_updated: true` in response = new scopes added; app must be reinstalled to workspace
