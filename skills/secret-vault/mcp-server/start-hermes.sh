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
        DERIVED=$(python3 -c "import base64,os; print(base64.b64decode(os.environ['SWABBY_VAULT_KEY']).hex())" 2>/dev/null)
        if [ -n "$DERIVED" ]; then
            export VAULT_KEY="$DERIVED"
        fi
    elif [ -f "/root/.hermes/.env" ]; then
        . /root/.hermes/.env 2>/dev/null
        if [ -n "$SWABBY_VAULT_KEY" ]; then
            DERIVED=$(python3 -c "import base64,os; print(base64.b64decode(os.environ['SWABBY_VAULT_KEY']).hex())" 2>/dev/null)
            if [ -n "$DERIVED" ]; then
                export VAULT_KEY="$DERIVED"
            fi
        fi
    fi
fi

exec python3 "$(dirname "$0")/server.py"
