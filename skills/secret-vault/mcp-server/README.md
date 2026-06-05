# Secret Vault — MCP Server

An MCP server that wraps the secret-vault CLI skill, exposing it as tools
callable by Claude Code. The critical security property: **secret values and
the master key are captured via native OS dialogs and never pass through the
LLM endpoint.**

## Security Contract

| What the LLM sees | What the LLM never sees |
|---|---|
| Secret key names (`github.token`) | Secret values |
| Tags, created date, rotated date | The vault master key |
| Operation results (`"stored"`, `"deleted"`) | Decrypted vault contents |

When you ask Claude to store a secret, it calls `vault_set(name="github.token")`.
The MCP server then opens a native macOS password dialog. You type the value there.
It goes directly from the dialog into the encrypted vault file — never through
the LLM API.

---

## Prerequisites

```bash
pip3 install cryptography mcp
```

`mcp` 1.0+ is required. `cryptography` is shared with the CLI skill.

---

## Installation

### 1. Register the server in `~/.claude.json`

Open `~/.claude.json` and add to the top-level `mcpServers` object:

```json
{
  "mcpServers": {
    "secret-vault": {
      "type": "stdio",
      "command": "python3",
      "args": ["/path/to/skills/secret-vault/mcp-server/server.py"]
    }
  }
}
```

Replace `/path/to/` with the actual path to your skills checkout, e.g.:
```
~/repos/claude-skills/skills/secret-vault/mcp-server/server.py
```

### 2. Allow the tools in `~/.claude/settings.json`

Add to the `permissions.allow` array:

```json
"mcp__secret-vault__vault_status",
"mcp__secret-vault__vault_init",
"mcp__secret-vault__vault_list",
"mcp__secret-vault__vault_set",
"mcp__secret-vault__vault_rotate",
"mcp__secret-vault__vault_delete",
"mcp__secret-vault__vault_exists",
"mcp__secret-vault__vault_get_metadata",
"mcp__secret-vault__vault_update_tags",
"mcp__secret-vault__vault_rekey"
```

### 3. Restart Claude Code

The server spawns as a subprocess on first tool use. No daemon to start.

---

## First-Run Behaviour

On macOS, the server auto-initializes the vault on first use:

1. Generates a random 256-bit key
2. Stores it in the macOS Keychain under `agent-secret-vault`
3. Creates `~/.agent/vault/vault.enc`

From that point on, all subsequent calls are silent — the Keychain handles
key resolution without prompting.

To use a passphrase instead of the Keychain:

```
Ask Claude: "Initialize the vault with a passphrase"
```

This calls `vault_init(key_tier="passphrase")` and prompts via native dialog.

---

## Vault Storage

```
~/.agent/vault/
├── vault.enc       # AES-256-GCM encrypted JSON — all secrets live here
├── .vault-meta     # Key tier, salt (if passphrase), created date
└── audit.log       # Append-only log: timestamps + key names, no values
```

The encryption format is identical to the CLI skill — both tools read and
write the same `vault.enc` file.

---

## Tools Reference

### `vault_status`
Check initialization state, key tier, and number of stored secrets.

**Ask Claude:** `"What's my vault status?"`

---

### `vault_init(key_tier, force?)`
Initialize or re-initialize the vault.

| `key_tier` | Behaviour |
|---|---|
| `keychain` | Random 256-bit key stored in OS Keychain (default on macOS) |
| `passphrase` | Argon2id-derived key — prompts via native dialog |
| `env` | Reads `VAULT_KEY` hex env var |

> **Warning:** Re-initializing creates a new empty vault, permanently destroying
> all stored secrets. The tool refuses if secrets exist unless `force=True` is
> passed. Use `vault_rekey` to rotate the master key while preserving secrets.

**Ask Claude:** `"Initialize the vault"` or `"Initialize with a passphrase"`

---

### `vault_rekey(new_key_tier)`
Rotate the vault master key while preserving all stored secrets.

Decrypts with the current key, generates or derives a new key via native
dialog (for passphrase), re-encrypts every secret under the new key, and
updates the key tier. The new key never passes through the LLM.

| `new_key_tier` | Behaviour |
|---|---|
| `keychain` | New random key stored in OS Keychain |
| `passphrase` | New passphrase collected via native dialog |
| `env` | New key read from `VAULT_KEY` env var |

**Ask Claude:** `"Rekey the vault"` or `"Rotate the vault master key to use a passphrase"`

---

### `vault_list(tags?)`
List all stored secret names, tags, and timestamps. **Values are never shown.**

**Ask Claude:** `"List my secrets"` or `"List secrets tagged env:prod"`

---

### `vault_set(name, tags?)`
Store a new secret or overwrite an existing one.

The value is **not** a parameter — a native macOS password dialog opens and
captures it directly. The LLM only receives the key name.

**Ask Claude:** `"Store a secret called github.token"` or `"Save my AWS access key as aws.access_key_id tagged env:prod,service:aws"`

---

### `vault_rotate(name)`
Replace an existing secret's value. Same dialog-capture behaviour as `vault_set`.
Records a rotation timestamp.

**Ask Claude:** `"Rotate my github.token"`

---

### `vault_delete(name)`
Permanently remove a secret.

**Ask Claude:** `"Delete the secret github.token"`

---

### `vault_exists(name)`
Check whether a key exists without retrieving its value.

**Ask Claude:** `"Does github.token exist in the vault?"`

---

### `vault_get_metadata(name)`
Return tags, created date, and last-rotated date for a secret. **No value.**

**Ask Claude:** `"Show me the metadata for aws.access_key_id"`

---

### `vault_update_tags(name, tags)`
Replace all tags on a secret without touching its value.

**Ask Claude:** `"Tag github.token with env:prod,service:github"`

---

## Key Naming Convention

Use dot-separated namespaces for discoverability:

```
service.credential_type
aws.access_key_id
aws.secret_access_key
github.pat
github.token
azure.client_secret
slack.bot_token
anthropic.api_key
```

---

## Relationship to the CLI Skill

The MCP server and CLI script (`scripts/vault.py`) share the same vault file
and encryption format. Use whichever is more convenient:

| Use case | Tool |
|---|---|
| Asking Claude to manage secrets | MCP server (values never hit LLM) |
| Scripting / CI pipelines | CLI (`vault.py get key --export`) |
| Bulk import from `.env` file | CLI (`vault.py import secrets.env`) |
| Editing a complex JSON secret | CLI (`vault.py edit file.enc`) |

> **Warning:** `vault.py get <key>` prints the value to stdout. If this output
> is captured into an LLM context (e.g. as a tool result), the secret is
> exposed. Use the MCP server when Claude needs to reference secrets.

---

## Gotchas

- **Keychain prompt on first use:** macOS may show a Keychain authorization
  dialog the first time a new session accesses `agent-secret-vault`. Click
  "Always Allow" to suppress future prompts.
- **Passphrase mode re-prompts every session:** The master key is cached in
  the server process memory. When you open a new Claude Code session, the
  passphrase dialog appears on the first vault tool call.
- **No value retrieval tool by design:** There is no `vault_get_value` tool.
  This is intentional — if you need a secret injected into a command, use
  `vault.py get key --export` in a shell script outside of Claude.
- **Binary secrets:** Files with non-UTF-8 content (SSH keys, etc.) are stored
  as base64. The CLI skill handles these natively via file-based operations.
- **Vault location is fixed:** `~/.agent/vault/` — not configurable in this
  version.
