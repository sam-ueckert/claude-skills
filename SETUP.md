# Setup Guide

Complete setup instructions for all skills in this repo.

## Prerequisites

- **Node.js** v18+ (`node --version`)
- **npm** v8+ (`npm --version`)
- **Claude Code** CLI installed ([docs](https://code.claude.com/docs/en))

## 1. Clone the Repo

```bash
git clone https://github.com/sam-ueckert/claude-skills.git
cd claude-skills
```

## 2. Install Dependencies

### Mermaid

```bash
npm install -g @mermaid-js/mermaid-cli
```

Verify:
```bash
mmdc --version
# Should output 11.x.x or higher
```

#### Platform-specific notes

**macOS (Apple Silicon & Intel):**
- No extra setup needed. Puppeteer downloads a compatible Chromium binary automatically during `npm install`.
- If you see "Failed to launch browser" errors, try: `npx puppeteer browsers install chrome`

**Linux x86_64:**
- Same as Mac — Puppeteer handles Chromium.
- If on a headless server, you may need display libs: `sudo apt install -y libnss3 libatk-bridge2.0-0 libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 libgbm1 libpango-1.0-0 libasound2`

**Linux ARM64 (Raspberry Pi, etc.):**
- Puppeteer does **not** bundle ARM64 Chromium. Install system Chromium:
  ```bash
  sudo apt install -y chromium-browser
  ```
- The render script (`mermaid/scripts/render.sh`) detects Linux and automatically uses `mermaid/puppeteer-config.json` which points to `/usr/bin/chromium-browser`.
- If your Chromium is at a different path, edit `puppeteer-config.json`:
  ```json
  {
    "executablePath": "/path/to/your/chromium",
    "args": ["--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"]
  }
  ```

### Lucidchart (when ready)

Lucidchart requires an API key. See [Lucidchart setup](#lucidchart-api-key) below.

## 3. Symlink Skills into Claude Code

Claude Code discovers skills from `~/.claude/skills/` (personal) or `.claude/skills/` (per-project).

### Option A: Personal skills (all projects)

```bash
# From the repo root
ln -sf "$(pwd)/mermaid" ~/.claude/skills/mermaid
ln -sf "$(pwd)/lucidchart" ~/.claude/skills/lucidchart
```

### Option B: Per-project skills

```bash
# From your project root
mkdir -p .claude/skills
ln -sf /path/to/claude-skills/mermaid .claude/skills/mermaid
ln -sf /path/to/claude-skills/lucidchart .claude/skills/lucidchart
```

### OpenClaw

For OpenClaw, symlink into your workspace `skills/` directory:

```bash
# From your OpenClaw workspace (e.g., ~/repos/swabby-brain)
ln -sf /path/to/claude-skills/mermaid skills/mermaid
ln -sf /path/to/claude-skills/lucidchart skills/lucidchart
```

## 4. Verify

### Mermaid

Create a test diagram:
```bash
cat > /tmp/test.mmd << 'EOF'
graph TD
    A[Hello] --> B[World]
EOF

# Use the render script
bash mermaid/scripts/render.sh /tmp/test.mmd /tmp/test.png

# Check output
file /tmp/test.png
# Should show: PNG image data, ...
```

In Claude Code:
```
> /mermaid
> draw a flowchart showing a CI/CD pipeline
```

### Claude Code auto-discovery

After symlinking, restart Claude Code. Skills appear when you type `/` and are also triggered automatically when relevant (e.g., "draw a diagram" will activate the mermaid skill).

## 5. Lucidchart API Key

> Not yet required — the Lucidchart skill is in planning.

When ready:

1. Go to [lucidchart.com](https://lucidchart.com) → Account Settings → API Tokens
2. Create a new API key with grants: `lucidchart`, `user.profile`
3. Store the key securely:
   - **Claude Code:** Set `LUCID_API_KEY` environment variable
   - **OpenClaw:** Encrypt with vault and reference from skill scripts

## Updating

```bash
cd claude-skills
git pull
```

Skills are symlinked, so updates are instant — no reinstall needed.

## Troubleshooting

| Issue | Platform | Fix |
|---|---|---|
| `Failed to launch browser` | Mac/Linux x86 | Run `npx puppeteer browsers install chrome` |
| `Failed to launch browser` | Linux ARM64 | Install system Chromium: `sudo apt install chromium-browser` |
| `mmdc: command not found` | All | Run `npm install -g @mermaid-js/mermaid-cli` |
| Diagram renders blank | All | Check Mermaid syntax at [mermaid.live](https://mermaid.live) |
| Wrong Chromium path (ARM64) | Linux ARM64 | Edit `mermaid/puppeteer-config.json` → `executablePath` |
| `Syntax error: ")" unexpected` | Linux ARM64 | Puppeteer downloaded x86 binary — ensure puppeteer-config.json is used |
