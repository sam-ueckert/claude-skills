#!/usr/bin/env bash
# check-drift.sh — diff vault-mcp's server.py and vault_core.py against both dependent repos

VAULT_MCP="${VAULT_MCP_DIR:-$HOME/repos/vault-mcp}"
AI_SKILLS="${AI_SKILLS_CATALOG_DIR:-$HOME/repos/ai-skills-catalog}"
CLAUDE_SKILLS="${CLAUDE_SKILLS_DIR:-$HOME/repos/claude-skills}"

FILES=("server.py" "vault_core.py")

DEPENDENTS=(
    "$AI_SKILLS/skills/secret-vault/mcp-server"
    "$CLAUDE_SKILLS/skills/secret-vault/mcp-server"
)

drifted=0

for dest_dir in "${DEPENDENTS[@]}"; do
    for f in "${FILES[@]}"; do
        src="$VAULT_MCP/$f"
        dst="$dest_dir/$f"
        if [ ! -f "$dst" ]; then
            echo "MISSING  $dst"
            drifted=$((drifted + 1))
        elif ! diff -q "$src" "$dst" > /dev/null 2>&1; then
            echo "DRIFTED  $dst"
            diff "$src" "$dst" | head -20
            echo "---"
            drifted=$((drifted + 1))
        else
            echo "ok       $dst"
        fi
    done
done

echo ""
if [ $drifted -eq 0 ]; then
    echo "All copies in sync with vault-mcp."
else
    echo "$drifted file(s) out of sync. Run: bash $VAULT_MCP/sync.sh"
    exit 1
fi
