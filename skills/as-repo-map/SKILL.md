---
name: as-repo-map
description: >
  Reference map of sam-ueckert's GitHub repo ecosystem. Auto-triggers when working
  across repos to provide context on ownership, sync relationships, submodule
  dependencies, and where code should live. Use when starting work in any connected
  repo, when a change has cross-repo implications, or when deciding where new code
  should live.
user-invokable: true
argument-hint: "[show|check-submodules|where-does-X-live]"
---

# Repo Ecosystem Map

**68 repos total** (13 public, 55 private). Last audited: 2026-06-08.
Active core: 9 repos updated in last 30 days.

---

## Tier Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         swabby-brain                                │
│              (agent identity + submodule integration hub)           │
│  submodules: vault-mcp, claude-skills, hermes-tools,                │
│              session-janitor, openclaw-ops, foreman                 │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ pulls from
     ┌─────────────────────┼───────────────────────┐
     ▼                     ▼                       ▼
  SKILLS               MEMORY               ORCHESTRATION
  ─────────────────    ─────────────────    ─────────────────
  claude-skills        oc-memory            foreman
  claude-autoskill     bosun                cyrano-prototype
  hermes-tools         session-janitor      openclaw-ops
  vault-mcp            swabby-memory
  agent-behaviour-
    bootstrap

     ▼
  INFRASTRUCTURE
  ─────────────────────────────
  infra-bootstrap (Ansible IaC)
  nemoclaw-k3s (active deploy)
  raspi_server (Pi 5 + k3s)
```

---

## Submodule Relationships

### swabby-brain (the hub)
```
swabby-brain/
├── skills/claude-skills      → sam-ueckert/claude-skills
├── skills/hermes-tools       → sam-ueckert/hermes-tools
├── skills/session-janitor    → sam-ueckert/session-janitor
├── skills/vault-mcp          → sam-ueckert/vault-mcp
├── services/openclaw-ops     → sam-ueckert/openclaw-ops
└── foreman/                  → sam-ueckert/foreman
```

> When updating any of these repos, also `cd` into the swabby-brain checkout and
> `git submodule update --remote <path>` + commit to advance the pointer.

---

## Sync Relationships (non-submodule copies)

| File | Source of truth | Copies in |
|---|---|---|
| `secret-vault/mcp-server/server.py` | `sam-ueckert/vault-mcp` | `wwt/ai-skills-catalog`, `sam-ueckert/claude-skills` |
| `secret-vault/mcp-server/vault_core.py` | `sam-ueckert/vault-mcp` | `wwt/ai-skills-catalog`, `sam-ueckert/claude-skills` |

Run `bash ~/repos/vault-mcp/sync.sh` after editing vault-mcp files.
See `as-vault-mcp-sync` for full redirect workflow.

---

## Fork Relationships

| Derived | Source | Type | Notes |
|---|---|---|---|
| `wwt/hackathon-tm7` | `sam-ueckert/foreman` | Conceptual fork | Not a GitHub fork. hackathon-tm7 branched from foreman's codebase for the WWT hackathon. Changes to shared job dispatch logic should propagate back to foreman. |

---

## Repo Purposes & "Where does X live?"

### Skills & Agent Tooling
| Repo | Purpose | Visibility |
|---|---|---|
| `sam-ueckert/claude-skills` | **Public personal skill catalog.** OpenClaw/Hermes deployment helpers. No vetting required. | Public |
| `wwt/ai-skills-catalog` | **WWT corporate skill catalog.** Genericized, enterprise-ready only. No internal endpoints, tokens, or WWT-specific config. | Private |
| `sam-ueckert/claude-autoskill` | Auto-extracts SKILL.md files from conversation turns. Generates `as-*` skills via hooks. | Public |
| `sam-ueckert/hermes-tools` | Memory capture bridge — PreCompact hook + session_sweep cron. Pushes to Archy MCP. | Public |
| `sam-ueckert/vault-mcp` | Standalone MCP server for encrypted secret storage. Source of truth for server.py. | Public |
| `sam-ueckert/agent-behaviour-bootstrap` | Shared behavior config across OpenClaw, Claude Code, Cursor. | Public |

**Rule:** If a skill works for anyone → `wwt/ai-skills-catalog`. If it's personal infra / OpenClaw-specific → `sam-ueckert/claude-skills`. Deployment wrappers (start-hermes.sh etc.) → the tool's own repo.

### Memory & Persistence
| Repo | Purpose | Status |
|---|---|---|
| `sam-ueckert/oc-memory` | Main memory server. SQLite + FTS5 + ONNX embeddings. 12 MCP tools. | Active |
| `sam-ueckert/bosun` | Private MCP gateway. Memory + orchestration + transcript lifecycle. k8s. | Active |
| `sam-ueckert/session-janitor` | Transcript trimmer + memory extractor. Multi-gateway. Cron-driven. | Active |
| `sam-ueckert/swabby-memory` | Earlier memory impl (Ollama). | Stable / lower priority |

### Orchestration
| Repo | Purpose | Status |
|---|---|---|
| `sam-ueckert/foreman` | MCP job dispatcher. DAG subtask decomposition. FastAPI + Postgres + pgvector + Nemotron NIM. Live on hack1 (100.109.108.33). | Active |
| `wwt/hackathon-tm7` | WWT hackathon fork of foreman. | Active — sync significant changes back to foreman |
| `sam-ueckert/cyrano-prototype` | NLang→Ansible pipeline. JWT/Keycloak, Vue 3, 544 tests. | Active research |
| `sam-ueckert/openclaw-ops` | OpenClaw gateway watchdog + auto-remediation. | Active |

### Infrastructure
| Repo | Purpose | Status |
|---|---|---|
| `sam-ueckert/infra-bootstrap` | Ansible IaC. Bootstraps OCP, k3scontroller (Pi 5), slc-jmp. 8 roles. Tailscale IPs. | Active |
| `sam-ueckert/nemoclaw-k3s` | NemoClaw (Foreman + OpenClaw) on worker-pi. Docker Compose + k3s. | Active — canonical deploy |
| `sam-ueckert/raspi_server` | k3s + Plex + Pi-hole + Tailscale on Raspberry Pi. | Active |
| `sam-ueckert/paperclip-k3s` | Earlier deploy iteration. | Superseded by nemoclaw-k3s |

---

## Decision Guide

**Working on the secret vault server?**
→ Edit in `vault-mcp`, run `sync.sh`, commit dependents. See `as-vault-mcp-sync`.

**Foreman change that's also relevant to hackathon-tm7?**
→ Make change in `sam-ueckert/foreman`, then cherry-pick or PR into `wwt/hackathon-tm7`.

**hackathon-tm7 improvement that should feed back to foreman?**
→ Open a PR from hackathon-tm7 into foreman (or manually port the commit). The fork flows both ways.

**New skill for public use?**
→ `sam-ueckert/claude-skills`. If genericized enough for WWT: also PR to `wwt/ai-skills-catalog`.

**New skill for WWT corporate use only?**
→ PR to `wwt/ai-skills-catalog` directly. Verify no internal hardcoding.

**swabby-brain needs the latest from a submodule?**
→ `git -C ~/repos/swabby-brain submodule update --remote skills/vault-mcp` (or whichever).

**Something changed in oc-memory / bosun / session-janitor?**
→ Also update swabby-brain submodule pointer so the hub stays current.

---

## Active Foreman Endpoints (for reference)
```
hack1 Tailscale IP: 100.109.108.33
:9000  — MCP endpoint
:8080  — Supervisor UI
:8000  — Nemotron NIM
:8001  — Retriever
:5432  — Postgres
```

---

## Obsolescence Notes
- `paperclip-k3s`, `paperclip-on-pi` → superseded by `nemoclaw-k3s`
- `swabby-memory` → functionally replaced by `oc-memory`; kept for reference
- `cyrano` (docs-only) → implementation lives in `cyrano-prototype`
- 40+ repos last updated >6 months ago are learning materials / deprecated experiments
