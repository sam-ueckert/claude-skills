# GitLab Skill

Create projects, push code, manage CI/CD variables on GitLab.com or self-hosted instances.

## Quick Start

```bash
# Store your PAT (one-time)
python3 secret-vault/scripts/vault.py set gitlab.token glpat-yourtoken

# For self-hosted, also store the host
python3 secret-vault/scripts/vault.py set gitlab.host https://gitlab.your-company.com

# Create a project
python3 scripts/gitlab.py create-project --name my-project --private

# Push local code
python3 scripts/gitlab.py push --project you/my-project --dir ./my-project

# Add a CI/CD variable (masked)
python3 scripts/gitlab.py add-variable --project you/my-project --key AWS_KEY --value "AKIA..." --masked
```

## Self-Hosted Support

Self-hosted GitLab is a first-class citizen. Just store your instance URL:

```bash
python3 secret-vault/scripts/vault.py set gitlab.host https://gitlab.your-company.com
```

All API calls automatically route to your instance.
