#!/usr/bin/env bash
set -euo pipefail

REPO="${SKILL_INDEX_REPO:-ueckerts/claude-skills}"
BRANCH="${SKILL_INDEX_BRANCH:-main}"
CACHE_DIR="$HOME/.cache/skill-index"
CACHE_FILE="$CACHE_DIR/${REPO//\//_}_${BRANCH}.json"
CACHE_TTL=3600  # 1 hour in seconds
VAULT_SCRIPT="$(cd "$(dirname "$0")/../../secret-vault/scripts" && pwd)/vault.py"

mkdir -p "$CACHE_DIR"

# Resolve GitHub token: env var first, then secret-vault
resolve_token() {
  local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
  if [[ -n "$token" ]]; then
    echo "$token"
    return
  fi
  # Try secret-vault
  if [[ -f "$VAULT_SCRIPT" ]]; then
    token=$(python3 "$VAULT_SCRIPT" get github.token 2>/dev/null) || true
    if [[ -n "$token" ]]; then
      echo "$token"
      return
    fi
  fi
}

# --- helpers ---

cache_is_fresh() {
  [[ -f "$CACHE_FILE" ]] || return 1
  local now age mtime
  now=$(date +%s)
  if [[ "$(uname)" == "Darwin" ]]; then
    mtime=$(stat -f %m "$CACHE_FILE")
  else
    mtime=$(stat -c %Y "$CACHE_FILE")
  fi
  age=$((now - mtime))
  (( age < CACHE_TTL ))
}

# Fetch repo tree, find SKILL.md files, extract frontmatter
build_index() {
  local tree_url="https://api.github.com/repos/${REPO}/git/trees/${BRANCH}?recursive=1"
  local token
  token=$(resolve_token)
  local headers=(-H "Accept: application/vnd.github+json")
  if [[ -n "$token" ]]; then
    headers+=(-H "Authorization: Bearer ${token}")
  fi

  # Get all SKILL.md paths (top-level only: <dir>/SKILL.md)
  local response paths
  response=$(curl -s "${headers[@]}" "$tree_url") || {
    echo "Error: failed to fetch repo tree. Is GITHUB_TOKEN set for private repos?" >&2
    exit 1
  }
  # Check for API errors
  if echo "$response" | jq -e '.message' &>/dev/null; then
    echo "Error: $(echo "$response" | jq -r '.message') — set GITHUB_TOKEN or GH_TOKEN for private repos" >&2
    exit 1
  fi
  paths=$(echo "$response" | jq -r '.tree[]
      | select(.path | test("^[^/]+/SKILL\\.md$"))
      | .path')

  if [[ -z "$paths" ]]; then
    echo "[]" > "$CACHE_FILE"
    return
  fi

  local results="[]"
  while IFS= read -r path; do
    local skill_name="${path%%/*}"
    local raw_url="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${path}"
    local content
    content=$(curl -sf "${headers[@]}" "$raw_url") || continue

    # Parse YAML frontmatter
    local fm
    fm=$(echo "$content" | sed -n '/^---$/,/^---$/p' | sed '1d;$d')
    local name desc
    name=$(echo "$fm" | grep '^name:' | sed 's/^name:[[:space:]]*//' | tr -d '"')
    desc=$(echo "$fm" | grep '^description:' | sed 's/^description:[[:space:]]*//' | tr -d '"')

    [[ -z "$name" ]] && name="$skill_name"

    results=$(echo "$results" | jq \
      --arg dir "$skill_name" \
      --arg name "$name" \
      --arg desc "$desc" \
      '. + [{"directory": $dir, "name": $name, "description": $desc}]')
  done <<< "$paths"

  echo "$results" > "$CACHE_FILE"
}

ensure_index() {
  if ! cache_is_fresh; then
    build_index
  fi
}

# --- commands ---

cmd_list() {
  ensure_index
  jq -r '.[] | "  \(.name)\n    \(.description)\n"' "$CACHE_FILE"
}

cmd_search() {
  local query="${1:?Usage: skill-index.sh search <query>}"
  ensure_index
  local q_lower
  q_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')
  jq -r --arg q "$q_lower" '
    .[] | select(
      (.name | ascii_downcase | contains($q)) or
      (.description | ascii_downcase | contains($q))
    ) | "  \(.name)\n    \(.description)\n"
  ' "$CACHE_FILE"
}

cmd_show() {
  local skill="${1:?Usage: skill-index.sh show <skill-name>}"
  local raw_url="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${skill}/SKILL.md"
  local token
  token=$(resolve_token)
  local headers=()
  if [[ -n "$token" ]]; then
    headers+=(-H "Authorization: Bearer ${token}")
  fi
  curl -sf "${headers[@]}" "$raw_url" || {
    echo "Error: skill '${skill}' not found in ${REPO}" >&2
    exit 1
  }
}

cmd_refresh() {
  rm -f "$CACHE_FILE"
  build_index
  local count
  count=$(jq length "$CACHE_FILE")
  echo "Refreshed index: ${count} skills found in ${REPO} (${BRANCH})"
}

# --- main ---

case "${1:-help}" in
  list)    cmd_list ;;
  search)  cmd_search "${2:-}" ;;
  show)    cmd_show "${2:-}" ;;
  refresh) cmd_refresh ;;
  *)
    echo "Usage: skill-index.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list              List all available skills"
    echo "  search <query>    Search skills by keyword"
    echo "  show <name>       Show full SKILL.md for a skill"
    echo "  refresh           Force refresh the cached index"
    ;;
esac
