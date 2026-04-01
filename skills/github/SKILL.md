---
name: github
description: >
  Create GitHub repositories, push local code, manage Actions secrets, and configure
  repo settings. Use this skill whenever the user wants to create a GitHub repo, push
  code to GitHub, add GitHub Actions secrets, set up branch protection, generate CI/CD
  workflows, or manage any GitHub repository settings. Requires a GitHub Personal Access
  Token stored in secret-vault or GITHUB_TOKEN env var.
user-invokable: true
args:
  - name: action
    description: The action to perform (create-repo, push, add-secret, list-repos)
    required: true
  - name: target
    description: Repo name, owner/repo, or other target identifier
    required: false
---

# GitHub Skill

Create repos, push code, manage secrets, and configure CI/CD on GitHub via the API.

## Authentication

Requires a GitHub Fine-grained PAT stored in secret-vault as `github.pat` or `GITHUB_TOKEN` env var.
For setup instructions, see [references/pat-setup.md](references/pat-setup.md).

Required PAT scopes:
- **Repository**: Read & Write (create repos, push code)
- **Secrets**: Read & Write (manage Actions secrets)
- **Administration**: Read & Write (branch protection, repo settings)

## Operations

### Create a repository
```bash
python3 scripts/github.py create-repo --name <repo-name> [--private] [--description "..."]
```

### Push a local directory to GitHub
```bash
python3 scripts/github.py push --repo <owner/repo> --dir <local-path> [--branch main]
```
Initializes git if needed, creates the remote repo if it doesn't exist, and pushes.

### Add a GitHub Actions secret
```bash
python3 scripts/github.py add-secret --repo <owner/repo> --name SECRET_NAME --value "..."
```
Uses libsodium sealed-box encryption as required by the GitHub API.

### List repositories
```bash
python3 scripts/github.py list-repos [--limit 20]
```

## CI/CD Workflow Templates

Read `schemas/workflow-templates.yaml` for starter GitHub Actions workflows:
- **Python**: lint, test, Docker build
- **Node**: lint, test, Docker build
- **Terraform**: fmt, validate, plan, apply
- **Docker**: build, push to GHCR

Templates are auto-selected based on project type when used with env-scaffolder.

## Repo Defaults

Read `schemas/repo-defaults.yaml` for default repository settings:
- Branch protection rules
- Default labels
- Auto-merge and squash settings

## Scripts

- `scripts/github.py` — Main CLI. Run `python3 scripts/github.py --help`

## How This Differs from Native `gh` CLI

See [references/vs-gh-cli.md](references/vs-gh-cli.md) for a full comparison.

## Gotchas

- Fine-grained PATs expire — set a calendar reminder for rotation
- `add-secret` requires `pynacl` (libsodium) for sealed-box encryption — `pip install pynacl` first
- Classic PATs and fine-grained PATs have different scope models — don't mix them up
- Rate limit: 5000 req/hr authenticated; the script doesn't retry on 429
- Creating a repo doesn't add a remote to your local git — you still need `git remote add`

## Integration

- **secret-vault**: Reads `github.pat` for authentication
- **env-scaffolder**: Provides workflow templates for generated projects
- **playbook-generator**: Can generate a "PAT rotation playbook"
