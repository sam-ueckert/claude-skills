# Setup Guide

## Quick Start

```bash
git clone https://github.com/<your-fork>/claude-skills.git
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
2. Install npm dependencies (mermaid-cli, defuddle)
3. Install Python dependencies (cryptography for secret-vault)
4. Auto-discover all skills (any directory with a `SKILL.md`) and symlink them into `~/.claude/skills/`
5. Verify mermaid rendering works

## Prerequisites

| Dependency | Required by | Install |
|---|---|---|
| Node.js v18+ | mermaid | `brew install node` / `winget install OpenJS.NodeJS.LTS` |
| npm | mermaid, defuddle | comes with Node.js |
| git | setup script | `xcode-select --install` / `winget install Git.Git` |
| Python 3 | secret-vault | `brew install python` / `winget install Python.Python.3.12` |
| curl + jq | lucidchart, skill-index | pre-installed on macOS; `sudo apt install curl jq` on Linux |

## Manual Setup

If you prefer not to use the setup script:

### 1. Install Dependencies

```bash
npm install -g @mermaid-js/mermaid-cli   # mermaid skill
npm install -g defuddle                    # defuddle skill
pip3 install cryptography                  # secret-vault skill
```

### 2. Link Skills

Skills are auto-discovered by the setup script, but you can link them manually:

**macOS / Linux (symlinks):**
```bash
mkdir -p ~/.claude/skills
# Link individual skills
ln -sf "$(pwd)/mermaid" ~/.claude/skills/mermaid
ln -sf "$(pwd)/secret-vault" ~/.claude/skills/secret-vault
# ... or link all skills at once
for d in */SKILL.md; do
    skill="$(dirname "$d")"
    ln -sf "$(pwd)/$skill" ~/.claude/skills/$skill
done
```

**Windows (directory junctions):**
```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude\skills" -Force
# Link individual skills
cmd /c mklink /J "$env:USERPROFILE\.claude\skills\mermaid" "$PWD\mermaid"
# ... or link all skills at once
Get-ChildItem -Directory | Where-Object { Test-Path "$($_.FullName)\SKILL.md" } | ForEach-Object {
    cmd /c mklink /J "$env:USERPROFILE\.claude\skills\$($_.Name)" $_.FullName
}
```

### 3. Per-project Skills (optional)

Instead of global install, link into a specific project:

```bash
mkdir -p .claude/skills
ln -sf /path/to/claude-skills/mermaid .claude/skills/mermaid
```

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
The mermaid render script auto-detects ARM64 and uses `mermaid/puppeteer-config.json`.

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
