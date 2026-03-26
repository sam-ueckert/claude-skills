# Secret Vault

Encrypted local credential storage for automation engineers. AES-256-GCM encryption with tiered key management.

## Quick Start

```bash
# Install dependency
pip install cryptography

# Initialize vault (passphrase mode — simplest)
python3 scripts/vault.py init --passphrase

# Store a secret
python3 scripts/vault.py set aws.access_key_id AKIAIOSFODNN7EXAMPLE

# Retrieve it
python3 scripts/vault.py get aws.access_key_id

# List all stored keys
python3 scripts/vault.py list
```

## Key Management Options

| Tier | Best For | Command |
|------|----------|---------|
| OS Keychain | Local development | `vault.py init --keychain` |
| Env Variable | CI/CD pipelines | `vault.py init --env` |
| Cloud KMS | Enterprise (planned) | `vault.py init --kms aws` |
| Passphrase | Quick setup, portable | `vault.py init --passphrase` |

## Integration

Other skills in this repo use secret-vault automatically:

- `cloud-provisioning` stores credentials after onboarding
- `github` and `gitlab` read PATs before API calls
- `env-scaffolder` references vault key names in `.env.example`

## File Layout

```
~/.claude/vault/
├── vault.enc        # Encrypted secrets (safe to backup)
├── .vault-meta      # Key tier, salt, creation date
└── audit.log        # Access log (no values)
```
