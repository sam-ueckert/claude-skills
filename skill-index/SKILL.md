---
name: skill-index
description: "Browse and search a curated index of Claude Code skills from a GitHub repo. Use when the user wants to find, list, browse, or install Claude skills, or asks what skills are available."
---

# Skill Index

Browse and search Claude Code skills from a remote GitHub repository.

## Setup

Set the source repo (defaults to this repo):

```bash
export SKILL_INDEX_REPO="ueckerts/claude-skills"  # owner/repo
export SKILL_INDEX_BRANCH="main"                    # optional, default: main
```

### Authentication (for private repos)

The script resolves a GitHub token in this order:
1. `GITHUB_TOKEN` or `GH_TOKEN` environment variable
2. `github.token` key from the **secret-vault** skill

To store the token in the vault (recommended):
```bash
python3 secret-vault/scripts/vault.py set github.token <your-token>
```

## Scripts

All scripts are in this skill's `scripts/` directory.

- **macOS / Linux**: `bash scripts/skill-index.sh <command>` (requires `curl` and `jq`)
- **Windows**: `pwsh scripts/skill-index.ps1 <command>` (uses `Invoke-RestMethod`)

### List all skills

```bash
bash scripts/skill-index.sh list
pwsh scripts/skill-index.ps1 list   # Windows
```

Displays all skills with their name and description.

### Search skills

```bash
bash scripts/skill-index.sh search "diagram"
```

Searches skill names and descriptions (case-insensitive). Returns matching skills.

### Show skill details

```bash
bash scripts/skill-index.sh show <skill-name>
```

Fetches and displays the full SKILL.md for a given skill.

### Refresh cache

```bash
bash scripts/skill-index.sh refresh
```

Forces a refresh of the cached skill index. The cache lives at `~/.cache/skill-index/` and expires after 1 hour.

## Workflow

1. User asks "what skills are available?" or "find a skill for diagrams"
2. Run `list` or `search` to find relevant skills
3. Run `show <name>` to get full details
4. User can then install by cloning/copying the skill directory into their project

## Notes

- The index is built by scanning top-level directories in the repo for `SKILL.md` files
- Skill metadata (name, description) is parsed from YAML frontmatter
- Results are cached locally for 1 hour to avoid rate limits
- Works with any GitHub repo that follows the `<skill-name>/SKILL.md` convention
