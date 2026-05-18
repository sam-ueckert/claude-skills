#!/usr/bin/env bash
# Switch, list, or show active Anthropic auth profile
# Usage: auth-switch.sh [--gateway slack|discord|both] [status|list|switch <profile>]
#
# --gateway defaults to both (shows/switches both gateways)
# OPENCLAW_AUTH_PROFILES env var still works as an override for single-file use
set -uo pipefail

# Gateway configs
DISCORD_AUTH="$HOME/.openclaw/agents/main/agent/auth-profiles.json"
SLACK_AUTH="$HOME/.openclaw-slack/agents/main/agent/auth-profiles.json"
DISCORD_RESTART="$HOME/bin/safe-gateway-restart.sh"
SLACK_RESTART="$HOME/bin/safe-slack-restart.sh"

# Parse --gateway flag
GATEWAY="both"
if [[ "${1:-}" == "--gateway" ]]; then
    GATEWAY="${2:-both}"
    shift 2
fi

ACTION="${1:-status}"
TARGET="${2:-}"

# If OPENCLAW_AUTH_PROFILES is set explicitly, use legacy single-file mode
if [[ -n "${OPENCLAW_AUTH_PROFILES:-}" ]]; then
    AUTH_FILES=("$OPENCLAW_AUTH_PROFILES")
    GATEWAY_LABELS=("custom")
else
    case "$GATEWAY" in
        discord) AUTH_FILES=("$DISCORD_AUTH");      GATEWAY_LABELS=("discord") ;;
        slack)   AUTH_FILES=("$SLACK_AUTH");         GATEWAY_LABELS=("slack") ;;
        both)    AUTH_FILES=("$DISCORD_AUTH" "$SLACK_AUTH"); GATEWAY_LABELS=("discord" "slack") ;;
        *)       echo "Error: --gateway must be slack, discord, or both"; exit 1 ;;
    esac
fi

show_status() {
    local file="$1" label="$2"
    if [[ ! -f "$file" ]]; then
        echo "[$label] Error: auth-profiles.json not found at $file"
        return 1
    fi
    python3 -c "
import json
with open('$file') as f:
    d = json.load(f)
lg = d.get('lastGood', {}).get('anthropic', '(none)')
stats = d.get('usageStats', {})
print(f'[$label] Active profile: {lg}')
for name, p in d['profiles'].items():
    s = stats.get(name, {})
    marker = '→' if name == lg else ' '
    errors = s.get('errorCount', 0)
    last_fail = s.get('lastFailureAt', 0)
    last_used = s.get('lastUsed', 0)
    print(f'  {marker} {name}')
    print(f'      lastUsed: {last_used}')
    print(f'      errors:   {errors}')
    if last_fail:
        print(f'      lastFail: {last_fail}')
print()
"
}

do_switch() {
    local file="$1" label="$2" target="$3"
    if [[ ! -f "$file" ]]; then
        echo "[$label] Error: auth-profiles.json not found at $file"
        return 1
    fi
    python3 -c "
import json, sys
with open('$file') as f:
    d = json.load(f)
target = '$target'
if target not in d['profiles']:
    print(f'[$label] Error: profile \"{target}\" not found')
    print(f'  Available: {list(d[\"profiles\"].keys())}')
    sys.exit(1)
old = d.get('lastGood', {}).get('anthropic', '(none)')
d.setdefault('lastGood', {})['anthropic'] = target
d.setdefault('usageStats', {}).setdefault(target, {}).update({
    'errorCount': 0, 'lastFailureAt': 0, 'lastUsed': 0
})
with open('$file', 'w') as f:
    json.dump(d, f, indent=2)
print(f'[$label] Switched: {old} → {target}')
"
}

case "$ACTION" in
    status)
        for i in "${!AUTH_FILES[@]}"; do
            show_status "${AUTH_FILES[$i]}" "${GATEWAY_LABELS[$i]}"
        done
        ;;

    list)
        for i in "${!AUTH_FILES[@]}"; do
            file="${AUTH_FILES[$i]}"
            label="${GATEWAY_LABELS[$i]}"
            if [[ -f "$file" ]]; then
                echo "[$label]"
                python3 -c "
import json
with open('$file') as f:
    d = json.load(f)
for name in d['profiles']:
    print(f'  {name}')
"
            fi
        done
        ;;

    switch)
        if [[ -z "$TARGET" ]]; then
            echo "Usage: auth-switch.sh [--gateway slack|discord|both] switch <profile-name>"
            exit 1
        fi
        FAILED=0
        for i in "${!AUTH_FILES[@]}"; do
            do_switch "${AUTH_FILES[$i]}" "${GATEWAY_LABELS[$i]}" "$TARGET" || FAILED=1
        done
        [[ $FAILED -eq 1 ]] && exit 1
        echo ""
        echo "Restart gateway(s) to take effect:"
        for label in "${GATEWAY_LABELS[@]}"; do
            case "$label" in
                discord) echo "  $DISCORD_RESTART \"switch to $TARGET\"" ;;
                slack)   echo "  $SLACK_RESTART \"switch to $TARGET\"" ;;
            esac
        done
        ;;

    *)
        echo "Usage: auth-switch.sh [--gateway slack|discord|both] [status|list|switch <profile>]"
        exit 1
        ;;
esac
