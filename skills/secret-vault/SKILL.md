---
name: secret-vault
description: >
  Store, encrypt, decrypt, and rotate API keys, tokens, and credentials locally using
  AES-256-GCM encryption. Use this skill whenever the user mentions API keys, secrets,
  tokens, credentials, passwords, service accounts, or needs to securely store/retrieve
  sensitive values. Also triggers when other skills (cloud-provisioning, github, gitlab)
  need to persist credentials after onboarding.
user-invokable: true
args:
  - name: action
    description: The action to perform (init, set, get, list, rotate, delete, import, export)
    required: true
  - name: key
    description: The secret key name (e.g. "aws.access_key_id", "github.pat")
    required: false
---

# Secret Vault

Encrypted local credential storage with tiered key management.

## Installation

```bash
# Install Python dependency
pip3 install cryptography

# Register the skill (OpenClaw)
ln -sf ~/repos/claude-skills/skills/secret-vault skills/secret-vault

# Initialize the vault (first time)
python3 skills/secret-vault/scripts/vault.py init
```

**Key management options** (choose one):
- `--keychain` — OS keychain (recommended for local dev — key never touches disk)
- `--passphrase` — Argon2id-derived key (no infrastructure required)
- `--kms aws/azure/gcp` — Cloud KMS (enterprise)

**Claude Code:**
Add to `CLAUDE.md`: `read ~/repos/claude-skills/skills/secret-vault/SKILL.md` The vault is a single
encrypted JSON file that holds all secrets, decrypted on demand and never written to
disk in plaintext.

## Architecture

```
~/.agent/vault/
├── vault.enc          # AES-256-GCM encrypted JSON (the actual secrets)
├── vault.schema.json  # JSON Schema defining vault structure
├── .vault-meta        # Unencrypted metadata: created date, last-rotated, version
└── audit.log          # Append-only log of access events (no secret values)
```

## Key Management Tiers

The encryption key (vault master key) is resolved in priority order:

1. **OS Keychain** (recommended for local dev)
   - macOS: Keychain Access via `security` CLI
   - Linux: Secret Service API via `secret-tool`
   - The key never touches disk
   - Command: `python3 scripts/vault.py init --keychain`

2. **Environment Variable** (CI/CD pipelines)
   - Reads `VAULT_KEY` from the environment
   - Integrates with GitHub Actions secrets, GitLab CI variables, Azure DevOps
   - Command: `export VAULT_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")`

3. **Cloud KMS** (enterprise)
   - AWS KMS, Azure Key Vault, or GCP Cloud KMS
   - Uses envelope encryption: cloud KMS wraps the local data key
   - Full IAM-gated audit trail
   - Command: `python3 scripts/vault.py init --kms aws --key-id alias/agent-vault`

4. **Passphrase** (fallback, no infrastructure needed)
   - Argon2id key derivation from a user-provided passphrase
   - Salt stored in `.vault-meta`
   - Command: `python3 scripts/vault.py init --passphrase`

## Vault Operations

### Initialize a new vault
```bash
python3 scripts/vault.py init [--keychain | --env | --kms <provider> | --passphrase]
```

### Store a secret
```bash
python3 scripts/vault.py set <key> <value> [--tags env:prod,service:aws]
```
Keys use dot notation: `aws.access_key_id`, `github.pat`, `azure.client_secret`

### Retrieve a secret
```bash
python3 scripts/vault.py get <key> [--export]
```
`--export` outputs as `export KEY=value` for shell sourcing.

### List keys (no values shown)
```bash
python3 scripts/vault.py list [--tags service:aws]
```

### Rotate a secret
```bash
python3 scripts/vault.py rotate <key> <new_value>
```
Logs the rotation event with timestamp. Old value is overwritten, not archived.

### Import secrets from a file
```bash
python3 scripts/vault.py import secrets.env [--tags service:aws] [--keep]
```
Accepts `.env` (KEY=VALUE) or JSON (`{"key": "value"}`) format.
The file is **securely deleted** after import (overwritten with random data, then removed).
Use `--keep` to preserve the file.

This is the safe way to add secrets without sending them through the AI agent — write them to a
file yourself, then ask the agent to run the import.

### Delete a secret
```bash
python3 scripts/vault.py delete <key>
```

### Export for CI/CD
```bash
python3 scripts/vault.py export --format github-actions > .env.ci
python3 scripts/vault.py export --format gitlab-ci
python3 scripts/vault.py export --format env
```

## Vault File Format

See [references/vault-format.md](references/vault-format.md) for the decrypted JSON structure.

## Safe Import (No LLM Exposure)

For adding secrets without exposing them to the AI agent, see [references/safe-import.md](references/safe-import.md).

## Security Considerations

See [references/security.md](references/security.md) for security notes and caveats.

## Gotchas

- `vault.py get` outputs to stdout — if piped into agent chat, the secret goes to the LLM API
- Keychain init on headless Linux requires `gnome-keyring-daemon` or similar running
- Passphrase mode: losing the passphrase = losing the vault (no recovery)
- `.vault-meta` contains the salt — deleting it makes passphrase-derived keys unrecoverable
- `import` shreds the source file by default — use `--keep` if you need it
- File permissions: `vault.enc` should be 600; the script doesn't enforce this

## Integration with Other Skills

- **cloud-provisioning**: After onboarding, stores credentials via `vault.py set`
- **github / gitlab**: Reads PATs via `vault.py get github.pat` before API calls
- **env-scaffolder**: References vault key names in generated `.env.example` files
- **playbook-generator**: Can generate a "credential rotation playbook" from vault metadata

## Schemas

Read `schemas/vault-schema.json` for the full JSON Schema defining the vault format.

## Scripts

- `scripts/vault.py` — The main vault CLI. Run `python3 scripts/vault.py --help` for usage.
