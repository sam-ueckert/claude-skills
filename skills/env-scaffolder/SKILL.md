---
name: env-scaffolder
description: >
  Scaffold project environments with directory structure, configuration files, .env
  templates, and dependency manifests based on project type. Use this skill whenever
  the user wants to bootstrap a new project, create a project skeleton, scaffold an
  environment, set up a new repo structure, or generate boilerplate configuration.
user-invokable: true
args:
  - name: project_type
    description: The type of project to scaffold (python-api, node-api, terraform, docker-compose, agent-skill)
    required: true
  - name: name
    description: Project name
    required: false
---

# Env Scaffolder

Generates project scaffolding based on project type: directory structure, config files,
`.env.example` with secret-vault key references, CI/CD starter configs, and dependency
manifests.

## How It Works

1. **Identify project type** — ask the user or infer from context
2. **Load template** — read the matching template from `schemas/project-types.yaml`
3. **Customize** — apply user-specified options (name, cloud, CI provider, etc.)
4. **Generate** — create all files and directories
5. **Connect** — reference secret-vault key names in `.env.example`, suggest github/gitlab
   skill for remote setup

## Supported Project Types

Read `schemas/project-types.yaml` for the full list. Current types:

- **python-api** — FastAPI/Flask project with venv, pytest, Docker
- **node-api** — Express/Fastify project with npm, jest, Docker
- **terraform** — IaC project with module structure, state backend config
- **docker-compose** — Multi-service project with compose file, networks, volumes
- **agent-skill** — Meta: scaffold a new agent skill with SKILL.md, schemas/, scripts/

## Generated Files (example: python-api)

```
my-project/
├── .env.example          # References vault keys: AWS_ACCESS_KEY_ID=${vault:aws.access_key_id}
├── .gitignore
├── Dockerfile
├── docker-compose.yaml
├── pyproject.toml
├── requirements.txt
├── src/
│   ├── __init__.py
│   ├── main.py
│   └── config.py         # Reads from env vars
├── tests/
│   ├── __init__.py
│   └── test_main.py
├── .github/
│   └── workflows/
│       └── ci.yaml       # Or .gitlab-ci.yml based on CI provider
└── README.md
```

## Gotchas

- `${vault:key.name}` in .env.example is a reminder notation, not actual interpolation — users must manually pull from vault
- The `agent-skill` project type is meta (scaffolds a skill) — don't confuse with the skill-creator skill

## Integration

- `.env.example` uses `${vault:key.name}` notation — a reminder to pull from secret-vault
- CI config templates come from github/gitlab skill's workflow/pipeline templates
- Terraform projects reference cloud-provisioning credentials

## Schemas

- `schemas/project-types.yaml` — all project type definitions
