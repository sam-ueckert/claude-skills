# claude-skills

Public personal skill catalog for Claude Code. Skills here are personal tools and
OpenClaw/Hermes deployment helpers.

## Repo hierarchy

This repo contains **synced copies** of files that have canonical homes elsewhere.
When Claude is asked to edit these files, redirect the edit to the source repo, then
run sync.sh + commit here.

| File | Source of truth | Sync command |
|---|---|---|
| `skills/secret-vault/mcp-server/server.py` | [sam-ueckert/vault-mcp](https://github.com/sam-ueckert/vault-mcp) | `bash ~/repos/vault-mcp/sync.sh` |
| `skills/secret-vault/mcp-server/vault_core.py` | [sam-ueckert/vault-mcp](https://github.com/sam-ueckert/vault-mcp) | `bash ~/repos/vault-mcp/sync.sh` |

## Purpose

`sam-ueckert/claude-skills` is for **public access** to personal tools — skills are
published here so they can be shared and discovered. Code does not need to be
enterprise-vetted to live here.

For WWT corporate-ready, genericized skills, see `wwt/ai-skills-catalog`.

## Autoskill: vault-mcp-sync

If you're about to edit `server.py` or `vault_core.py` under `skills/secret-vault/mcp-server/`,
**stop** — invoke the `as-vault-mcp-sync` autoskill instead, which will redirect the
change to the source repo and sync back.
