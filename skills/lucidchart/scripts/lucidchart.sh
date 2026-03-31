#!/usr/bin/env bash
set -euo pipefail

# Lucidchart REST API helper
# Requires: LUCID_API_KEY env var, curl, jq

BASE_URL="https://api.lucid.co"

if [[ -z "${LUCID_API_KEY:-}" ]]; then
  echo "Error: LUCID_API_KEY environment variable is not set." >&2
  echo "Create an API key at https://developer.lucid.co and set it." >&2
  exit 1
fi

api() {
  local method="$1" path="$2"
  shift 2
  curl -sf "$BASE_URL$path" \
    -X "$method" \
    -H "Authorization: Bearer $LUCID_API_KEY" \
    -H "Lucid-Api-Version: 1" \
    "$@"
}

cmd_create() {
  local title="${1:?Usage: lucidchart.sh create <title> [folder_id]}"
  local folder_id="${2:-}"
  local body
  body=$(jq -n --arg t "$title" '{title: $t, product: "lucidchart"}')
  if [[ -n "$folder_id" ]]; then
    body=$(echo "$body" | jq --argjson p "$folder_id" '. + {parent: $p}')
  fi
  local resp
  resp=$(api POST /documents -H "Content-Type: application/json" -d "$body")
  local doc_id edit_url
  doc_id=$(echo "$resp" | jq -r '.documentId')
  edit_url=$(echo "$resp" | jq -r '.editUrl')
  echo "Document ID: $doc_id"
  echo "Edit URL:    $edit_url"
  echo "$resp" | jq .
}

cmd_create_from_template() {
  local title="${1:?Usage: lucidchart.sh create-from-template <title> <template_uuid> [folder_id]}"
  local template="${2:?Template UUID required}"
  local folder_id="${3:-}"
  local body
  body=$(jq -n --arg t "$title" --arg tmpl "$template" '{title: $t, template: $tmpl}')
  if [[ -n "$folder_id" ]]; then
    body=$(echo "$body" | jq --argjson p "$folder_id" '. + {parent: $p}')
  fi
  local resp
  resp=$(api POST /documents -H "Content-Type: application/json" -d "$body")
  local doc_id edit_url
  doc_id=$(echo "$resp" | jq -r '.documentId')
  edit_url=$(echo "$resp" | jq -r '.editUrl')
  echo "Document ID: $doc_id"
  echo "Edit URL:    $edit_url"
  echo "$resp" | jq .
}

cmd_export() {
  local doc_id="${1:?Usage: lucidchart.sh export <document_id> <output_file>}"
  local output="${2:?Output file path required}"
  api GET "/documents/$doc_id" -H "Accept: image/png" -o "$output"
  echo "Exported to $output"
}

cmd_search() {
  local keywords="${1:?Usage: lucidchart.sh search <keywords>}"
  local body
  body=$(jq -n --arg k "$keywords" '{keywords: $k, product: ["lucidchart"]}')
  api POST /accounts/me/documents/search \
    -H "Content-Type: application/json" \
    -H "Lucid-Request-As: admin" \
    -d "$body" | jq .
}

cmd_get() {
  local doc_id="${1:?Usage: lucidchart.sh get <document_id>}"
  api GET "/documents/$doc_id" -H "Accept: application/json" | jq .
}

cmd_folders() {
  api GET /folders -H "Accept: application/json" | jq .
}

cmd_help() {
  cat <<'HELP'
Usage: lucidchart.sh <command> [args...]

Commands:
  create <title> [folder_id]                        Create a blank document
  create-from-template <title> <template> [folder]  Create from template
  export <document_id> <output.png>                  Export as PNG
  search <keywords>                                  Search documents
  get <document_id>                                  Get document info
  folders                                            List folders
  help                                               Show this help
HELP
}

case "${1:-help}" in
  create)                shift; cmd_create "$@" ;;
  create-from-template)  shift; cmd_create_from_template "$@" ;;
  export)                shift; cmd_export "$@" ;;
  search)               shift; cmd_search "$@" ;;
  get)                   shift; cmd_get "$@" ;;
  folders)              shift; cmd_folders "$@" ;;
  help|*)               cmd_help ;;
esac
