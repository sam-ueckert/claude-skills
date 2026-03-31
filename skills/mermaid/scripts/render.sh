#!/usr/bin/env bash
# Mermaid diagram renderer — cross-platform (Mac + Linux ARM64/x86)
# Usage: render.sh <input.mmd> <output.png> [theme] [width]
set -euo pipefail

INPUT="${1:?Usage: render.sh <input.mmd> <output.png> [theme] [width]}"
OUTPUT="${2:?Usage: render.sh <input.mmd> <output.png> [theme] [width]}"
THEME="${3:-dark}"
WIDTH="${4:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PUPPETEER_CONFIG="$SCRIPT_DIR/../puppeteer-config.json"

# Build mmdc args
ARGS=(-i "$INPUT" -o "$OUTPUT" -t "$THEME")
[[ -n "$WIDTH" ]] && ARGS+=(-w "$WIDTH")

# Platform detection: only use puppeteer config on Linux (ARM64 needs system Chromium)
if [[ "$(uname -s)" == "Linux" ]] && [[ -f "$PUPPETEER_CONFIG" ]]; then
    ARGS+=(-p "$PUPPETEER_CONFIG")
fi

exec mmdc "${ARGS[@]}"
