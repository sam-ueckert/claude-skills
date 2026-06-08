#!/bin/bash
# Wrapper for Hermes Agent: derive VAULT_KEY (hex) from SWABBY_VAULT_KEY (base64)
# and launch the MCP server.
#
# Hermes loads ~/.hermes/.env into process env, so SWABBY_VAULT_KEY
# is available directly. Falls back to sourcing the .env file if not set.
#
# Claude Code / OpenClaw on k3scontroller should use start.sh instead.

if [ -z "$VAULT_KEY" ]; then
    if [ -n "$SWABBY_VAULT_KEY" ]; then
        # Some env propagations strip the base64 padding; fix it
        PADDED_KEY="${SWABBY_VAULT_KEY}"
        case ${#PADDED_KEY} in
            42) PADDED_KEY="${PADDED_KEY}==" ;;
            43) PADDED_KEY="${PADDED_KEY}=" ;;
        esac
        DERIVED=$(python3 -c "import base64; print(base64.b64decode('${PADDED_KEY}').hex())" 2>/dev/null)
        if [ -n "$DERIVED" ]; then
            export VAULT_KEY="$DERIVED"
        fi
    fi
    if [ -z "$VAULT_KEY" ] && [ -f "/root/.hermes/.env" ]; then
        . /root/.hermes/.env 2>/dev/null
        if [ -n "$SWABBY_VAULT_KEY" ]; then
            PADDED_KEY="${SWABBY_VAULT_KEY}"
            case ${#PADDED_KEY} in
                42) PADDED_KEY="${PADDED_KEY}==" ;;
                43) PADDED_KEY="${PADDED_KEY}=" ;;
            esac
            DERIVED=$(python3 -c "import base64; print(base64.b64decode('${PADDED_KEY}').hex())" 2>/dev/null)
            if [ -n "$DERIVED" ]; then
                export VAULT_KEY="$DERIVED"
            fi
        fi
    fi
fi

exec python3 "$(dirname "$0")/server.py"
