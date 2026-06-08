---
name: as-vault-mcp-sync
description: >
  Manages the vault-mcp repo hierarchy. Auto-triggers when server.py or vault_core.py
  are about to be edited in a dependent repo (ai-skills-catalog or claude-skills).
  Redirects edits to sam-ueckert/vault-mcp (source of truth), then syncs copies back
  to all dependent repos. Also invocable on demand to sync or check drift.
user-invokable: true
argument-hint: "[sync|check|redirect]"
---

# vault-mcp Sync

Manages the single-source-of-truth hierarchy for the secret-vault MCP server code.

## Repo Hierarchy

```
sam-ueckert/vault-mcp  (SOURCE OF TRUTH)
  ├── server.py
  ├── vault_core.py
  ├── sync.sh           ← propagates to both dependents
  └── start-hermes.sh   ← Hermes Pi deployment launcher

  ┌── syncs to ──────────────────────────────────────────────┐
  │                                                           │
  ▼                                                           ▼
wwt/ai-skills-catalog                       sam-ueckert/claude-skills
  skills/secret-vault/mcp-server/             skills/secret-vault/mcp-server/
    server.py      (copy)                        server.py      (copy)
    vault_core.py  (copy)                        vault_core.py  (copy)
```

**Purpose of each repo:**
- `vault-mcp` — standalone MCP server; all code changes happen here
- `ai-skills-catalog` — WWT corporate skill catalog; genericized, enterprise-vetted
- `claude-skills` — public personal tools; OpenClaw/Hermes deployment helpers

## Auto-trigger: redirect edits in dependent repos

If you are about to modify `server.py` or `vault_core.py` in **ai-skills-catalog**
or **claude-skills**, do this instead:

```bash
# Step 1: make the change in vault-mcp
cd ~/repos/vault-mcp
# ... edit server.py or vault_core.py ...
git add server.py vault_core.py
git commit -m "description of change"
git push origin main

# Step 2: sync to all dependent repos
bash ~/repos/vault-mcp/sync.sh

# Step 3: commit each updated dependent repo
git -C ~/repos/ai-skills-catalog add skills/secret-vault/mcp-server/server.py skills/secret-vault/mcp-server/vault_core.py
git -C ~/repos/ai-skills-catalog commit -m "sync: server.py + vault_core.py from vault-mcp"
git -C ~/repos/ai-skills-catalog push

git -C ~/repos/claude-skills add skills/secret-vault/mcp-server/server.py skills/secret-vault/mcp-server/vault_core.py
git -C ~/repos/claude-skills commit -m "sync: server.py + vault_core.py from vault-mcp"
git -C ~/repos/claude-skills push
```

## Check for drift

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/check-drift.sh
```

Diffs vault-mcp's files against both dependent repos and reports any divergence.

## Manual sync (on demand)

```bash
bash ~/repos/vault-mcp/sync.sh
```

## Adding a new dependent repo

1. Add the repo's mcp-server path to `sync.sh` in vault-mcp under `DEPENDENT_PATHS`
2. Add a CLAUDE.md to that repo documenting the redirect rule
3. Update this skill's hierarchy diagram above
4. Commit vault-mcp

## Hierarchy config (machine-readable)

```json
{
  "source": {
    "repo": "sam-ueckert/vault-mcp",
    "local": "~/repos/vault-mcp",
    "files": ["server.py", "vault_core.py"]
  },
  "dependents": [
    {
      "repo": "wwt/ai-skills-catalog",
      "local": "~/repos/ai-skills-catalog",
      "dest": "skills/secret-vault/mcp-server"
    },
    {
      "repo": "sam-ueckert/claude-skills",
      "local": "~/repos/claude-skills",
      "dest": "skills/secret-vault/mcp-server"
    }
  ]
}
```
