---
name: skill-discovery
description: "Browse and search a curated index of AI agent skills from a GitHub repo. Use when the user wants to find, list, browse, or install skills, or asks what skills are available."
user-invokable: true
args:
  - name: action
    description: The action to perform (list, search, show, refresh)
    required: true
  - name: query
    description: Search query or skill name
    required: false
---

# Skill Index

Browse and search AI agent skills from a remote GitHub repository.

## Setup

Set the source repo (defaults to this repo):

```bash
export SKILL_INDEX_REPO="sam-ueckert/claude-skills"  # owner/repo
export SKILL_INDEX_BRANCH="main"                       # optional, default: main
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

- **macOS / Linux**: `bash scripts/skill-discovery.sh <command>` (requires `curl` and `jq`)
- **Windows**: `pwsh scripts/skill-discovery.ps1 <command>` (uses `Invoke-RestMethod`)

### List all skills

```bash
bash scripts/skill-discovery.sh list
pwsh scripts/skill-discovery.ps1 list   # Windows
```

Displays all skills with their name and description.

### Search skills

```bash
bash scripts/skill-discovery.sh search "diagram"
```

Searches skill names and descriptions (case-insensitive). Returns matching skills.

### Show skill details

```bash
bash scripts/skill-discovery.sh show <skill-name>
```

Fetches and displays the full SKILL.md for a given skill.

### Refresh cache

```bash
bash scripts/skill-discovery.sh refresh
```

Forces a refresh of the cached skill index. The cache lives at `~/.cache/skill-discovery/` and expires after 1 hour.

## Workflow

1. User asks "what skills are available?" or "find a skill for diagrams"
2. Run `list` or `search` to find relevant skills
3. Run `show <name>` to get full details
4. User can then install by cloning/copying the skill directory into their project

## Gotchas

- Cache lives at ~/.cache/skill-discovery/ and expires after 1 hour — stale results possible after repo updates
- Private repos require a GitHub token — without it, all API calls return 404 (not 401)
- The script parses YAML frontmatter only — skills without proper frontmatter won't appear

## Notes

- The index is built by scanning `skills/` directories in the repo for `SKILL.md` files
- Skill metadata (name, description) is parsed from YAML frontmatter
- Results are cached locally for 1 hour to avoid rate limits
- Works with any GitHub repo that follows the `skills/<skill-name>/SKILL.md` convention
