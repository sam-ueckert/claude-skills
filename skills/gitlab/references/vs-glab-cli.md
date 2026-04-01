# How This Differs from Native `glab` CLI

| | This skill | Native `glab` CLI |
|---|---|---|
| **Install required** | Python 3 only | `glab` CLI (`brew install glab`) |
| **Auth method** | PAT in secret-vault or `GITLAB_TOKEN` env var | `glab auth login` (OAuth or PAT) |
| **Auth storage** | Encrypted vault | `~/.config/glab-cli/config.yml` (plaintext) |
| **Self-hosted** | Set `gitlab.host` in vault — all API calls route automatically | `glab auth login --hostname` |
| **CI/CD templates** | Built-in `.gitlab-ci.yml` templates for Python, Node, Terraform, Docker | None — you write them yourself |
| **Project defaults** | Applies settings from `schemas/project-defaults.yaml` | Manual setup |
| **Offline-friendly** | Direct REST API calls, no CLI dependency | Requires `glab` binary |

Use this skill when `glab` isn't available, when you want encrypted token storage, or when you want opinionated project setup with pipeline templates baked in.
