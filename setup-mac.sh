#!/usr/bin/env bash
# Setup script for Claude Code skills on macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/sam-ueckert/claude-skills/main/setup-mac.sh | bash
#   or:  bash setup-mac.sh
set -uo pipefail

SKILLS_DIR="$HOME/repos/claude-skills"
OBSIDIAN_DIR="$HOME/repos/obsidian-skills"
CLAUDE_SKILLS="$HOME/.claude/skills"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Claude Code Skills — Mac Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Prerequisites ──────────────────────────────
echo "Checking prerequisites..."

if ! command -v node &>/dev/null; then
    fail "Node.js not found. Install: brew install node"
    exit 1
fi
ok "Node.js $(node --version)"

if ! command -v npm &>/dev/null; then
    fail "npm not found"
    exit 1
fi
ok "npm $(npm --version)"

if ! command -v git &>/dev/null; then
    fail "git not found. Install: xcode-select --install"
    exit 1
fi
ok "git $(git --version | awk '{print $3}')"

echo ""

# ── Clone repos ────────────────────────────────
echo "Setting up repos..."
mkdir -p "$HOME/repos"

if [ -d "$SKILLS_DIR" ]; then
    cd "$SKILLS_DIR" && git pull --quiet
    ok "claude-skills repo updated"
else
    git clone https://github.com/sam-ueckert/claude-skills.git "$SKILLS_DIR"
    ok "claude-skills repo cloned"
fi

if [ -d "$OBSIDIAN_DIR" ]; then
    cd "$OBSIDIAN_DIR" && git pull --quiet
    ok "obsidian-skills repo updated"
else
    git clone https://github.com/kepano/obsidian-skills.git "$OBSIDIAN_DIR"
    ok "obsidian-skills repo cloned"
fi

echo ""

# ── Install npm dependencies ──────────────────
echo "Installing dependencies..."

if command -v mmdc &>/dev/null; then
    ok "mermaid-cli already installed ($(mmdc --version))"
else
    echo "  Installing @mermaid-js/mermaid-cli (this may take a minute)..."
    if npm install -g @mermaid-js/mermaid-cli 2>&1 | tail -3; then
        ok "mermaid-cli installed"
    else
        warn "mermaid-cli install failed — try manually: npm install -g @mermaid-js/mermaid-cli"
    fi
fi

if command -v defuddle &>/dev/null; then
    ok "defuddle already installed"
else
    echo "  Installing defuddle..."
    if npm install -g defuddle 2>&1 | tail -3; then
        ok "defuddle installed"
    else
        warn "defuddle install failed — try manually: npm install -g defuddle"
    fi
fi

echo ""

# ── Symlink skills into Claude Code ───────────
echo "Linking skills into Claude Code (~/.claude/skills/)..."
mkdir -p "$CLAUDE_SKILLS"

# Custom skills (claude-skills repo)
for skill in mermaid lucidchart; do
    rm -rf "$CLAUDE_SKILLS/$skill" 2>/dev/null
    ln -sf "$SKILLS_DIR/$skill" "$CLAUDE_SKILLS/$skill"
    ok "$skill → claude-skills repo"
done

# Kepano's obsidian skills
for skill in obsidian-markdown obsidian-cli json-canvas obsidian-bases defuddle; do
    rm -rf "$CLAUDE_SKILLS/$skill" 2>/dev/null
    ln -sf "$OBSIDIAN_DIR/skills/$skill" "$CLAUDE_SKILLS/$skill"
    ok "$skill → obsidian-skills repo"
done

echo ""

# ── Verify ─────────────────────────────────────
echo "Verifying..."

# Test mermaid rendering
TESTFILE=$(mktemp /tmp/mermaid-test-XXXX.mmd)
cat > "$TESTFILE" << 'EOF'
graph LR
    A[Setup] --> B[Complete]
EOF
OUTFILE="${TESTFILE%.mmd}.png"

if mmdc -i "$TESTFILE" -o "$OUTFILE" -t dark &>/dev/null; then
    ok "Mermaid rendering works"
    rm -f "$TESTFILE" "$OUTFILE"
else
    warn "Mermaid rendering failed — try: npx puppeteer browsers install chrome"
    rm -f "$TESTFILE" "$OUTFILE"
fi

# Check obsidian CLI
if command -v obsidian &>/dev/null; then
    ok "Obsidian CLI available"
else
    warn "Obsidian CLI not found — install Obsidian 1.12+ for /obsidian-cli skill"
fi

# List final state
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installed Skills"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for d in "$CLAUDE_SKILLS"/*/; do
    skill=$(basename "$d")
    target=$(readlink "$d" 2>/dev/null || echo "local")
    echo -e "  ${GREEN}✓${NC} /$(printf '%-20s' "$skill") → $(echo "$target" | sed "s|$HOME|~|")"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}Done!${NC} Restart Claude Code to pick up skills."
echo "  Type / to see available skills."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
