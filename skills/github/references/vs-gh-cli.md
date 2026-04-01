# How This Differs from Native `gh` CLI

| | This skill | Native `gh` CLI |
|---|---|---|
| **Install required** | Python 3 only | `gh` CLI (`brew install gh`) |
| **Auth method** | PAT in secret-vault or `GITHUB_TOKEN` env var | `gh auth login` (OAuth or PAT) |
| **Auth storage** | Encrypted vault | `~/.config/gh/hosts.yml` (plaintext) |
| **CI/CD templates** | Built-in workflow templates for Python, Node, Terraform, Docker | None — you write them yourself |
| **Repo defaults** | Applies branch protection, labels, and settings from `schemas/repo-defaults.yaml` | Manual setup |
| **Offline-friendly** | Direct REST API calls, no CLI dependency | Requires `gh` binary |

Use this skill when `gh` isn't available, when you want encrypted token storage, or when you want opinionated repo setup with CI/CD templates baked in.
