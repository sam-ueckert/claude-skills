# Env Scaffolder

Bootstrap new projects with proper structure, config, and CI/CD in seconds.

## Quick Start

> "Scaffold a new FastAPI project called my-service"

> "Create a Terraform project for AWS with S3 backend"

> "Bootstrap a new Claude skill called my-awesome-skill"

## Supported Project Types

| Type | Description |
|------|-------------|
| `python-api` | FastAPI/Flask with Docker, pytest, CI |
| `node-api` | Express/Fastify with Docker, jest, CI |
| `terraform` | IaC with modules, environments, remote state |
| `docker-compose` | Multi-service with networking and volumes |
| `claude-skill` | Meta: scaffold a new skill for this repo |

## Integration

- `.env.example` references `secret-vault` key names
- CI configs use templates from `github`/`gitlab` skills
- Terraform projects reference `cloud-provisioning` credentials
