# claude-skills

Custom [Claude Code skills](https://code.claude.com/docs/en/skills) following the [AgentSkills.io](https://agentskills.io) open standard. These skills work in Claude Code CLI, OpenClaw, and any other AgentSkills-compatible agent.

## Skills

| Skill | Status | Description |
|---|---|---|
| [mermaid](mermaid/) | ✅ Ready | Render diagrams (flowcharts, mind maps, ERDs, sequence, Gantt, etc.) to PNG/SVG |
| [lucidchart](lucidchart/) | 🚧 Planned | Manage Lucidchart docs via REST API (create, export, share) |

## Quick Start

See [SETUP.md](SETUP.md) for full installation instructions.

```bash
# 1. Clone this repo
git clone https://github.com/sam-ueckert/claude-skills.git

# 2. Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# 3. Symlink skills into Claude Code
ln -sf "$(pwd)/claude-skills/mermaid" ~/.claude/skills/mermaid
ln -sf "$(pwd)/claude-skills/lucidchart" ~/.claude/skills/lucidchart

# 4. Use in Claude Code
# Type /mermaid or just ask Claude to "draw a diagram"
```

## Platform Support

| Platform | Status | Notes |
|---|---|---|
| macOS (Apple Silicon) | ✅ | Puppeteer bundles its own Chromium |
| macOS (Intel) | ✅ | Puppeteer bundles its own Chromium |
| Linux x86_64 | ✅ | Puppeteer bundles its own Chromium |
| Linux ARM64 (Pi) | ✅ | Uses system `chromium-browser` via puppeteer-config.json |

## License

MIT
