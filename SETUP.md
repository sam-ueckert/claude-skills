# Setup Guide

## Quick Start

```bash
git clone https://github.com/sam-ueckert/claude-skills.git
cd claude-skills
```

### macOS / Linux

```bash
bash setup.sh
```

### Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

The setup script will:
1. Check prerequisites (Node.js, npm, git, python3)
2. Install npm dependencies (mermaid-cli)
3. Install Python dependencies (cryptography for secret-vault)
4. Auto-discover all skills (any directory under `skills/` with a `SKILL.md`)
5. Verify mermaid rendering works

## Prerequisites

| Dependency | Required by | Install |
|---|---|---|
| Node.js v18+ | mermaid | `brew install node` / `winget install OpenJS.NodeJS.LTS` |
| npm | mermaid | comes with Node.js |
| git | setup script | `xcode-select --install` / `winget install Git.Git` |
| Python 3 | secret-vault, github, gitlab | `brew install python` / `winget install Python.Python.3.12` |
| curl + jq | lucidchart, skill-index | pre-installed on macOS; `sudo apt install curl jq` on Linux |

## Platform-Specific Wiring

### OpenClaw

Symlink skill directories into your workspace `skills/` folder. OpenClaw auto-discovers
any directory under `skills/` that contains a `SKILL.md` file.

```bash
# From your workspace root (e.g. ~/repos/my-agent-brain)
mkdir -p skills

# Symlink a single skill
ln -sf ~/repos/claude-skills/skills/mermaid skills/mermaid

# Symlink all skills at once
for d in ~/repos/claude-skills/skills/*/; do
    ln -sf "$d" "skills/$(basename "$d")"
done
```

Or register the skills directory globally in `openclaw.json` under `skills.paths`.

### Claude Code

Claude Code reads `CLAUDE.md` at session start. Add skill references there:

```markdown
## Skills

Read skill files on demand when the task requires them:
- **Diagrams**: `read ~/repos/claude-skills/skills/mermaid/SKILL.md`
- **Secrets**: `read ~/repos/claude-skills/skills/secret-vault/SKILL.md`
- **GitHub**: `read ~/repos/claude-skills/skills/github/SKILL.md`
- **GitLab**: `read ~/repos/claude-skills/skills/gitlab/SKILL.md`
- **Cloud**: `read ~/repos/claude-skills/skills/cloud-provisioning/SKILL.md`
- **Playbooks**: `read ~/repos/claude-skills/skills/playbook-generator/SKILL.md`
```

The agent will read the SKILL.md file the first time the skill is needed in a session.

### Cursor / Continue / Other Agents

Any agent that supports reading files on demand can use these skills. Reference the
`SKILL.md` path in your agent's system prompt or context file.

## Manual Setup

If you prefer not to use the setup script:

### 1. Install Dependencies

```bash
npm install -g @mermaid-js/mermaid-cli   # mermaid skill
pip3 install cryptography                  # secret-vault skill
```

### 2. Link Skills into Your Agent

Link skill directories into your AI agent's workspace `skills/` directory:

**macOS / Linux (symlinks):**
```bash
# From your agent workspace
mkdir -p skills

# Link individual skills
ln -sf /path/to/claude-skills/skills/mermaid skills/mermaid
ln -sf /path/to/claude-skills/skills/secret-vault skills/secret-vault

# ... or link all skills at once
for d in /path/to/claude-skills/skills/*/SKILL.md; do
    skill="$(basename "$(dirname "$d")")"
    ln -sf "$(dirname "$d")" "skills/$skill"
done
```

**Windows (directory junctions):**
```powershell
New-Item -ItemType Directory -Path "skills" -Force
Get-ChildItem -Path "C:\path\to\claude-skills\skills" -Directory | Where-Object {
    Test-Path "$($_.FullName)\SKILL.md"
} | ForEach-Object {
    cmd /c mklink /J "skills\$($_.Name)" $_.FullName
}
```

### OpenClaw

For OpenClaw, symlink into your workspace's `skills/` directory:
```bash
cd ~/repos/your-workspace
ln -sf /path/to/claude-skills/skills/mermaid skills/mermaid
```

Skills are auto-discovered when the agent starts.

## Platform Notes

**macOS** — No extra setup. Puppeteer downloads Chromium automatically.

**Linux x86_64** — Same as Mac. On headless servers you may need display libs:
```bash
sudo apt install -y libnss3 libatk-bridge2.0-0 libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 libgbm1 libpango-1.0-0 libasound2
```

**Linux ARM64** — Puppeteer doesn't bundle ARM64 Chromium. Install system Chromium:
```bash
sudo apt install -y chromium-browser
```
The mermaid render script auto-detects ARM64 and uses `skills/mermaid/puppeteer-config.json`.

**Windows** — Puppeteer downloads Chromium automatically. No extra setup needed.

## Updating

```bash
cd claude-skills
git pull
```

Skills are symlinked/junctioned, so updates are instant — no reinstall needed.

## Troubleshooting

| Issue | Platform | Fix |
|---|---|---|
| `Failed to launch browser` | Mac/Linux x86 | `npx puppeteer browsers install chrome` |
| `Failed to launch browser` | Linux ARM64 | `sudo apt install chromium-browser` |
| `mmdc: command not found` | All | `npm install -g @mermaid-js/mermaid-cli` |
| Diagram renders blank | All | Check syntax at [mermaid.live](https://mermaid.live) |
| `Execution policy` error | Windows | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| Junction not created | Windows | Run PowerShell as Administrator |
| `import cryptography` fails | All | `pip3 install cryptography` |
