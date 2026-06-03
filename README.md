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
| `/skill-discovery` | ✅ Ready | Browse and search the curated index of available skills from this repo |
| `/clip-img` | ✅ Ready | Paste clipboard images into a terminal-based AI agent via Raycast (macOS only) |

## Installation

### OpenClaw

```bash
git clone https://github.com/sam-ueckert/claude-skills.git
```

Then symlink skills into your agent workspace:

```bash
# From your OpenClaw workspace (e.g. ~/repos/my-brain)
for d in ~/repos/claude-skills/skills/*/; do
    skill="$(basename "$d")"
    ln -sf "$d" "skills/$skill"
done
```

Or add to `openclaw.json` to register the path globally:

```json
{
  "skills": {
    "paths": ["/home/youruser/repos/claude-skills/skills"]
  }
}
```

Skills are auto-discovered at session start.

### Claude Code

```bash
git clone https://github.com/sam-ueckert/claude-skills.git
bash claude-skills/setup.sh
```

The setup script installs dependencies and prints the paths to each skill. To use a skill in a project, add it to your `CLAUDE.md`:

```markdown
## Available Skills

To use a skill, read its SKILL.md file:
- Mermaid diagrams: read ~/repos/claude-skills/skills/mermaid/SKILL.md
- Secret vault: read ~/repos/claude-skills/skills/secret-vault/SKILL.md
- GitHub: read ~/repos/claude-skills/skills/github/SKILL.md
```

Then in any Claude Code session, the agent will load the skill on demand.

### Quick setup (both platforms)

```bash
git clone https://github.com/sam-ueckert/claude-skills.git
cd claude-skills
bash setup.sh
```

See [SETUP.md](SETUP.md) for full installation instructions.

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
│   ├── skill-discovery/   # Skill browser
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
