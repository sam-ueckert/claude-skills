---
name: github
description: >
  Create GitHub repositories, push local code, manage Actions secrets, and configure
  repo settings — all from Claude. Use this skill whenever the user wants to create a
  GitHub repo, push code to GitHub, add GitHub Actions secrets, set up branch protection,
  generate CI/CD workflows, or manage any GitHub repository settings. Also triggers when
  the user says "push this to GitHub", "create a repo", "set up CI", or mentions GitHub
  Actions, GitHub Pages, or GitHub API operations. Requires a GitHub Personal Access Token
  stored in secret-vault or GITHUB_TOKEN env var.
---

# GitHub Skill

Create repos, push code, manage secrets, and configure CI/CD on GitHub via the API.

## Prerequisites

A GitHub Fine-grained Personal Access Token (PAT) with these scopes:
- **Repository**: Read & Write (create repos, push code)
- **Secrets**: Read & Write (manage Actions secrets)
- **Administration**: Read & Write (branch protection, repo settings)

The PAT should be stored in secret-vault as `github.pat`, or set as `GITHUB_TOKEN` env var.

## Onboarding

If no token is configured, walk the user through:

1. Go to https://github.com/settings/tokens?type=beta (Fine-grained tokens)
2. Click **Generate new token**
3. Set token name: `claude-automation`
4. Set expiration: 90 days (recommend rotation via playbook-generator)
5. Under **Repository access**: select "All repositories" or specific repos
6. Under **Permissions → Repository permissions**:
   - Contents: Read & Write
   - Administration: Read & Write
   - Secrets: Read & Write
   - Workflows: Read & Write
   - Metadata: Read-only (auto-granted)
7. Click **Generate token**
8. ⚠️ **Copy the token NOW — it will not be shown again**
9. Store it: `python3 secret-vault/scripts/vault.py set github.pat ghp_...`

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

## Integration

- **secret-vault**: Reads `github.pat` for authentication
- **env-scaffolder**: Provides workflow templates for generated projects
- **playbook-generator**: Can generate a "PAT rotation playbook"
