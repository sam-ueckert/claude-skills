---
name: auth-switch
description: Switch which Anthropic auth profile (OAuth token) OpenClaw uses. Use when the user asks to switch API keys, swap auth tokens, change which account is active, check which profile is in use, or troubleshoot rate limiting by switching to the backup account.
user-invokable: true
args:
  - name: action
    description: The action to perform (status, list, switch)
    required: true
  - name: profile
    description: The profile name to switch to (e.g. "anthropic:backup")
    required: false
---

# Auth Profile Switcher

Switch between Anthropic OAuth auth profiles in OpenClaw.

## Commands

Resolve `scripts/auth-switch.sh` relative to this skill's directory.

```bash
# Show current active profile and stats
bash scripts/auth-switch.sh status

# List available profiles
bash scripts/auth-switch.sh list

# Switch to a specific profile
bash scripts/auth-switch.sh switch anthropic:backup
bash scripts/auth-switch.sh switch anthropic:openclaw
```

## After Switching

The switch updates `auth-profiles.json` locally. To take effect:
1. Use the `gateway` tool to restart: `gateway(action="restart", note="Switched auth profile to X")`
2. Or restart the gateway manually via `openclaw gateway restart`

## How It Works

- Sets `lastGood.anthropic` to the target profile
- Resets error count and failure timestamp on the target
- Sets `lastUsed` to 0 so OpenClaw's rotation picks it as the preferred (oldest-used) profile

## Gotchas

- Switching profiles updates auth-profiles.json but requires a gateway restart to take effect
- If the target profile's OAuth token is expired, the switch succeeds but API calls will fail after restart
- The script sets `lastUsed: 0` which makes the profile "oldest" for rotation — this is intentional, not a bug

## Notes

- OpenClaw auto-rotates between profiles on rate limit errors
- This skill forces a specific profile to be preferred
- Useful when one account is rate-limited and you want to immediately switch
- The non-preferred profile remains available as fallback
