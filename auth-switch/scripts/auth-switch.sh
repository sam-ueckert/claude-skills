#!/usr/bin/env bash
# Switch, list, or show active Anthropic auth profile
# Usage: auth-switch.sh [status|switch <profile>|list]
set -uo pipefail

AUTH_FILE="${OPENCLAW_AUTH_PROFILES:-$HOME/.openclaw/agents/main/agent/auth-profiles.json}"

if [[ ! -f "$AUTH_FILE" ]]; then
    echo "Error: auth-profiles.json not found at $AUTH_FILE"
    exit 1
fi

ACTION="${1:-status}"

case "$ACTION" in
    status)
        python3 -c "
import json
with open('$AUTH_FILE') as f:
    d = json.load(f)
lg = d.get('lastGood', {}).get('anthropic', '(none)')
stats = d.get('usageStats', {})
print(f'Active profile: {lg}')
print()
for name, p in d['profiles'].items():
    s = stats.get(name, {})
    marker = '→' if name == lg else ' '
    errors = s.get('errorCount', 0)
    last_fail = s.get('lastFailureAt', 0)
    last_used = s.get('lastUsed', 0)
    print(f'  {marker} {name}')
    print(f'    lastUsed: {last_used}')
    print(f'    errors: {errors}')
    if last_fail:
        print(f'    lastFailure: {last_fail}')
    print()
"
        ;;

    list)
        python3 -c "
import json
with open('$AUTH_FILE') as f:
    d = json.load(f)
for name in d['profiles']:
    print(name)
"
        ;;

    switch)
        TARGET="${2:-}"
        if [[ -z "$TARGET" ]]; then
            echo "Usage: auth-switch.sh switch <profile-name>"
            echo "Available profiles:"
            python3 -c "
import json
with open('$AUTH_FILE') as f:
    d = json.load(f)
for name in d['profiles']:
    print(f'  {name}')
"
            exit 1
        fi

        python3 -c "
import json, sys

with open('$AUTH_FILE') as f:
    d = json.load(f)

target = '$TARGET'
if target not in d['profiles']:
    print(f'Error: profile \"{target}\" not found')
    print(f'Available: {list(d[\"profiles\"].keys())}')
    sys.exit(1)

old = d.get('lastGood', {}).get('anthropic', '(none)')
d['lastGood'] = d.get('lastGood', {})
d['lastGood']['anthropic'] = target

# Reset error count on target so it's preferred
if 'usageStats' not in d:
    d['usageStats'] = {}
if target not in d['usageStats']:
    d['usageStats'][target] = {}
d['usageStats'][target]['errorCount'] = 0
d['usageStats'][target]['lastFailureAt'] = 0

# Set lastUsed to 0 so rotation picks it as oldest-used
d['usageStats'][target]['lastUsed'] = 0

with open('$AUTH_FILE', 'w') as f:
    json.dump(d, f, indent=2)

print(f'Switched: {old} → {target}')
print(f'Restart gateway to take effect.')
"
        ;;

    *)
        echo "Usage: auth-switch.sh [status|switch <profile>|list]"
        exit 1
        ;;
esac
