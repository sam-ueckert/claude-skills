---
name: gitlab
description: >
  Create GitLab projects, push local code, manage CI/CD variables, and configure
  project settings — for both GitLab.com and self-hosted instances. Use this skill
  whenever the user wants to create a GitLab project, push code to GitLab, add CI/CD
  variables, set up branch protection, generate pipeline configs, or manage any GitLab
  project settings.
user-invokable: true
args:
  - name: action
    description: The action to perform (create-project, push, add-variable, list-projects)
    required: true
  - name: target
    description: Project namespace/name or other target identifier
    required: false
---

# GitLab Skill

Create projects, push code, manage CI/CD variables, and configure pipelines on
GitLab.com or self-hosted instances.

## Authentication

Requires a GitLab PAT with `api` and `write_repository` scopes.

Store in secret-vault:
- `gitlab.token` — the PAT
- `gitlab.host` — instance URL (default: `https://gitlab.com`). Set this for self-hosted.

Or use env vars: `GITLAB_TOKEN`, `GITLAB_HOST`.

For setup instructions (GitLab.com and self-hosted), see [references/pat-setup.md](references/pat-setup.md).

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

## How This Differs from Native `glab` CLI

See [references/vs-glab-cli.md](references/vs-glab-cli.md) for a full comparison.

## Gotchas

- Self-hosted: if the instance uses a self-signed cert, set `REQUESTS_CA_BUNDLE` or `--no-verify`
- `api` scope is very broad — consider `read_api` + `write_repository` for narrower access
- CI variable masking requires the value to be at least 8 chars and match a regex
- Rate limit varies by instance — self-hosted admins may set it lower than gitlab.com

## GitLab API Notes

GitLab uses `PRIVATE-TOKEN` header (not `Authorization: Bearer`). The script handles
this transparently. Self-hosted instances just need `gitlab.host` set — all API calls
route there automatically.
