# GitHub Skill

Create repos, push code, manage Actions secrets, and configure CI/CD on GitHub.

## Quick Start

```bash
# Store your PAT (one-time)
python3 secret-vault/scripts/vault.py set github.pat ghp_yourtoken

# Create a repo
python3 scripts/github.py create-repo --name my-project --private

# Push local code
python3 scripts/github.py push --repo you/my-project --dir ./my-project

# Add an Actions secret
python3 scripts/github.py add-secret --repo you/my-project --name AWS_KEY --value "AKIA..."
```

## Dependencies

```bash
pip install pynacl   # Required for encrypting Actions secrets
```

## Onboarding

If you don't have a PAT yet, ask Claude: "Set up my GitHub credentials" — it will walk you through creating a fine-grained token with minimum required scopes.
