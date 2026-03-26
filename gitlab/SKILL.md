---
name: gitlab
description: >
  Create GitLab projects, push local code, manage CI/CD variables, and configure
  project settings — for both GitLab.com and self-hosted instances. Use this skill
  whenever the user wants to create a GitLab project, push code to GitLab, add CI/CD
  variables, set up branch protection, generate pipeline configs, or manage any GitLab
  project settings. Triggers on "push to GitLab", "create a GitLab project", "set up
  GitLab CI", or any mention of .gitlab-ci.yml, GitLab pipelines, or GitLab API
  operations. Self-hosted GitLab is a first-class citizen — just store the instance URL.
---

# GitLab Skill

Create projects, push code, manage CI/CD variables, and configure pipelines on
GitLab.com or self-hosted instances.

## Prerequisites

A GitLab Personal Access Token with these scopes:
- **api** — full API access (create projects, manage variables)
- **write_repository** — push code

Store in secret-vault:
- `gitlab.token` — the PAT
- `gitlab.host` — instance URL (default: `https://gitlab.com`). Set this for self-hosted.

Or use env vars: `GITLAB_TOKEN`, `GITLAB_HOST`.

## Onboarding

If no token is configured, walk the user through:

### GitLab.com
1. Go to https://gitlab.com/-/user_settings/personal_access_tokens
2. Click **Add new token**
3. Name: `claude-automation`, Expiration: 90 days
4. Scopes: `api`, `write_repository`
5. Click **Create personal access token**
6. ⚠️ **Copy the token NOW — it will not be shown again**
7. Store: `python3 secret-vault/scripts/vault.py set gitlab.token glpat-...`

### Self-Hosted GitLab
Same steps, but at `https://your-instance.com/-/user_settings/personal_access_tokens`

Then also store the host:
```bash
python3 secret-vault/scripts/vault.py set gitlab.host https://your-instance.com
```

## Operations

### Create a project
```bash
python3 scripts/gitlab.py create-project --name <n> [--private] [--description "..."]
```

### Push a local directory
```bash
python3 scripts/gitlab.py push --project <namespace/project> --dir <path> [--branch main]
```

### Add a CI/CD variable
```bash
python3 scripts/gitlab.py add-variable --project <namespace/project> --key VAR_NAME --value "..."
    [--masked] [--protected]
```

### List projects
```bash
python3 scripts/gitlab.py list-projects [--limit 20]
```

## Pipeline Templates

Read `schemas/pipeline-templates.yaml` for `.gitlab-ci.yml` starters:
- **Python**: lint, test, Docker build, push to GitLab Container Registry
- **Node**: lint, test, Docker build
- **Terraform**: fmt, validate, plan, apply with manual gate
- **Docker**: build, push to registry

## Project Defaults

Read `schemas/project-defaults.yaml` for default project settings.

## Scripts

- `scripts/gitlab.py` — Main CLI. Run `python3 scripts/gitlab.py --help`

## Key Difference from GitHub

GitLab uses `PRIVATE-TOKEN` header (not `Authorization: Bearer`). The script handles
this transparently. Self-hosted instances just need `gitlab.host` set — all API calls
route there automatically.
