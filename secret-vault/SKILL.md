---
name: secret-vault
description: >
  Store, encrypt, decrypt, and rotate API keys, tokens, and credentials locally using
  AES-256-GCM encryption. Use this skill whenever the user mentions API keys, secrets,
  tokens, credentials, passwords, service accounts, or needs to securely store/retrieve
  sensitive values. Also triggers when other skills (cloud-provisioning, github, gitlab)
  need to persist credentials after onboarding. Handles vault initialization, key
  management, secret rotation, and audit logging. Even if the user just says "save this
  key" or "I need to store my AWS credentials", use this skill.
---

# Secret Vault

Encrypted local credential storage with tiered key management. The vault is a single
encrypted JSON file that holds all secrets, decrypted on demand and never written to
disk in plaintext.

## Architecture

```
~/.claude/vault/
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
   - Reads `CLAUDE_VAULT_KEY` from the environment
   - Integrates with GitHub Actions secrets, GitLab CI variables, Azure DevOps
   - Command: `export CLAUDE_VAULT_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")`

3. **Cloud KMS** (enterprise)
   - AWS KMS, Azure Key Vault, or GCP Cloud KMS
   - Uses envelope encryption: cloud KMS wraps the local data key
   - Full IAM-gated audit trail
   - Command: `python3 scripts/vault.py init --kms aws --key-id alias/claude-vault`

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

## Vault File Format (decrypted)

```json
{
  "version": 1,
  "secrets": {
    "aws.access_key_id": {
      "value": "AKIA...",
      "tags": ["env:prod", "service:aws"],
      "created": "2025-03-25T10:00:00Z",
      "rotated": null
    }
  }
}
```

## Security Considerations

- The vault file (`vault.enc`) is safe to commit to version control (it's encrypted),
  but `.vault-meta` should be gitignored if it contains a passphrase salt you want private
- Never log or print secret values — the audit log records key names and operations only
- The `get` command outputs to stdout; pipe carefully
- Rotation does not propagate to cloud providers — use cloud-provisioning for that

## Integration with Other Skills

- **cloud-provisioning**: After onboarding, stores credentials via `vault.py set`
- **github / gitlab**: Reads PATs via `vault.py get github.pat` before API calls
- **env-scaffolder**: References vault key names in generated `.env.example` files
- **playbook-generator**: Can generate a "credential rotation playbook" from vault metadata

## Schemas

Read `schemas/vault-schema.json` for the full JSON Schema defining the vault format.

## Scripts

- `scripts/vault.py` — The main vault CLI. Run `python3 scripts/vault.py --help` for usage.
