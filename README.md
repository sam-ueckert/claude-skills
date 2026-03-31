# Agent Skills — Automation Engineer Toolkit

Reusable AI agent skills for infrastructure automation, cloud provisioning, DevOps workflows, and diagram rendering. Compatible with any AgentSkills-compatible agent (OpenClaw, Claude Code, etc.).

## Skills

| Skill | Status | Description |
|-------|--------|-------------|
| `/mermaid` | ✅ Ready | Render diagrams (flowcharts, mind maps, ERDs, sequence, Gantt, etc.) to PNG/SVG |
| `/lucidchart` | ✅ Ready | Manage Lucidchart documents via REST API — create, search, export as PNG, share |
| `/auth-switch` | ✅ Ready | Switch between Anthropic auth profiles in OpenClaw |
| `/secret-vault` | ✅ Ready | Encrypted local credential storage with AES-256-GCM, tiered key management |
| `/github` | ✅ Ready | Create repos, push code, manage Actions secrets, configure CI/CD on GitHub |
| `/gitlab` | ✅ Ready | Create projects, push code, manage CI/CD variables on GitLab.com or self-hosted |
| `/cloud-provisioning` | ✅ Ready | Onboard and provision compute credentials for AWS, Azure, and GCP |
| `/env-scaffolder` | ✅ Ready | Scaffold project environments with directory structure, configs, and CI/CD templates |
| `/playbook-generator` | ✅ Ready | Generate operational playbooks and SOPs conforming to organizational standards |
| `/skill-index` | ✅ Ready | Browse and search the curated index of available skills from this repo |
| `/clip-img` | ✅ Ready | Paste clipboard images into a terminal-based AI agent via Raycast (macOS only) |

## Setup

See [SETUP.md](SETUP.md) for full installation instructions.

```bash
# 1. Clone this repo
git clone https://github.com/sam-ueckert/claude-skills.git
cd claude-skills

# 2. Run the setup script (installs dependencies, links skills)
bash setup.sh          # macOS / Linux
pwsh setup.ps1         # Windows
```

## Available Tools

These skills provide the following tools:

**Mermaid:**
- `scripts/render.sh` / `scripts/render.ps1` — cross-platform Mermaid rendering

**Secret Vault:**
- `scripts/vault.py` — encrypted credential storage CLI

**GitHub / GitLab:**
- `scripts/github.py` / `scripts/gitlab.py` — API clients for repo management

**Cloud Provisioning:**
- `scripts/verify-credentials.sh` / `scripts/verify-credentials.ps1` — test cloud credentials

**Lucidchart:**
- `scripts/lucidchart.sh` / `scripts/lucidchart.ps1` / `scripts/create_diagram.py` — Lucidchart API client

**Auth Switch:**
- `scripts/auth-switch.sh` — OpenClaw auth profile management

**Skill Index:**
- `scripts/skill-index.sh` / `scripts/skill-index.ps1` — browse/search skill registry

## Usage Examples

### Render a diagram
```
/mermaid flowchart showing CI/CD pipeline
```

### Provision cloud credentials
```
/cloud-provisioning Set up AWS credentials
```

### Create a GitHub repo with CI/CD
```
/github create-repo --name my-project --private
```

### Generate an operational playbook
```
/playbook-generator deployment runbook for Azure AI Foundry
```

## Project Structure

```
claude-skills/
├── skills/
│   ├── mermaid/           # Diagram rendering
│   ├── lucidchart/        # Lucidchart API integration
│   ├── auth-switch/       # Auth profile switching
│   ├── secret-vault/      # Credential encryption
│   ├── github/            # GitHub API operations
│   ├── gitlab/            # GitLab API operations
│   ├── cloud-provisioning/# Cloud IAM onboarding
│   ├── env-scaffolder/    # Project scaffolding
│   ├── playbook-generator/# Operational playbooks
│   ├── skill-index/       # Skill browser
│   └── clip-img/          # Clipboard image paste (macOS)
├── setup.sh               # macOS/Linux setup
├── setup.ps1              # Windows setup
├── setup-mac.sh           # macOS-specific setup
├── SETUP.md               # Detailed setup guide
├── BRAINSTORM.md          # Future skill ideas
└── README.md
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS (Apple Silicon) | ✅ | Full support |
| macOS (Intel) | ✅ | Full support |
| Linux x86_64 | ✅ | Full support |
| Linux ARM64 (Pi) | ✅ | Mermaid uses system `chromium-browser` |
| Windows | ✅ | PowerShell scripts provided |

## License

MIT
