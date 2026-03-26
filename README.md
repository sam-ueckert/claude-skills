# Claude Skills — Automation Engineer Toolkit

Custom Claude skills for infrastructure automation, cloud provisioning, and DevOps workflows.

## Skills Index

| Skill | Description | Dependencies |
|-------|-------------|--------------|
| [secret-vault](secret-vault/) | Encrypted API key/credential storage (AES-256-GCM) | `cryptography` |
| [playbook-generator](playbook-generator/) | Standards-conformant playbook/runbook/SOP generation | — |
| [cloud-provisioning](cloud-provisioning/) | AWS/Azure/GCP credential onboarding with least-privilege IAM | Cloud CLIs |
| [env-scaffolder](env-scaffolder/) | Project scaffolding by type (Python, Node, Terraform, Docker) | — |
| [github](github/) | GitHub repo creation, push, Actions secrets, CI/CD | `pynacl` |
| [gitlab](gitlab/) | GitLab project creation, push, CI variables, self-hosted | — |

## How Skills Connect

```
cloud-provisioning ──► secret-vault ◄── github
                           │         ◄── gitlab
                           ▼
                    env-scaffolder ──► github/gitlab (CI templates)
                           │
                           ▼
                   playbook-generator (rotation playbooks)
```

- **secret-vault** is the hub — other skills store and retrieve credentials through it
- **cloud-provisioning** onboards cloud credentials, stores them in the vault
- **github/gitlab** read PATs from the vault, push code, manage CI/CD
- **env-scaffolder** generates project boilerplate referencing vault key names
- **playbook-generator** creates operational docs conforming to org standards

## Quick Start

```bash
# 1. Initialize the vault
pip install cryptography
python3 secret-vault/scripts/vault.py init --passphrase

# 2. Onboard to a cloud (ask Claude)
#    > "Set up my AWS credentials"

# 3. Store your GitHub PAT
python3 secret-vault/scripts/vault.py set github.pat ghp_yourtoken

# 4. Scaffold a project and push it
#    > "Create a FastAPI project called my-api and push it to GitHub"
```

## Design Principles

1. **Composable** — skills work standalone and integrate naturally
2. **Least privilege** — never request more access than needed
3. **Offline-first** — core functionality works without internet
4. **Standards-based** — JSON Schema, YAML, OpenAPI over custom formats
5. **Audit trail** — sensitive actions get logged

## Repository Structure

```
claude-skills/
├── README.md                   ← this file
├── BRAINSTORM.md               ← future skill ideas
├── secret-vault/
│   ├── SKILL.md
│   ├── README.md
│   ├── schemas/vault-schema.json
│   └── scripts/vault.py
├── playbook-generator/
│   ├── SKILL.md
│   ├── README.md
│   ├── schemas/baseline-standard.yaml
│   ├── schemas/org-standard-template.yaml
│   └── examples/azure-foundry-deployment.md
├── cloud-provisioning/
│   ├── SKILL.md
│   ├── README.md
│   ├── schemas/{aws,azure,gcp} policies
│   └── scripts/verify-credentials.sh
├── env-scaffolder/
│   ├── SKILL.md
│   ├── README.md
│   └── schemas/project-types.yaml
├── github/
│   ├── SKILL.md
│   ├── README.md
│   ├── schemas/{workflow-templates,repo-defaults}.yaml
│   └── scripts/github.py
└── gitlab/
    ├── SKILL.md
    ├── README.md
    ├── schemas/{pipeline-templates,project-defaults}.yaml
    └── scripts/gitlab.py
```
