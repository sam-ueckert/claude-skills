#!/usr/bin/env bash
# Setup script for Claude Code skills on macOS and Linux
# Usage: bash setup.sh
#
# Run from within the cloned repo, or set SKILLS_DIR to the repo path.
set -uo pipefail

# Resolve repo root: use SKILLS_DIR if set, otherwise the directory containing this script
if [[ -n "${SKILLS_DIR:-}" ]]; then
    REPO_DIR="$SKILLS_DIR"
elif [[ -f "$(dirname "$0")/setup.sh" ]]; then
    REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
else
    echo "Run this script from within the claude-skills repo, or set SKILLS_DIR." >&2
    exit 1
fi

CLAUDE_SKILLS="$HOME/.claude/skills"
OS="$(uname -s)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

ask_yes_no() {
    # ask_yes_no "Question?" → returns 0 for yes, 1 for no
    local prompt="$1"
    while true; do
        read -r -p "$(echo -e "${CYAN}?${NC} $prompt [y/n] ")" answer
        case "$answer" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "  Please answer y or n." ;;
        esac
    done
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Claude Code Skills — Setup ($OS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Prerequisites ──────────────────────────────
echo "Checking prerequisites..."

# Node.js
if ! command -v node &>/dev/null; then
    fail "Node.js not found (required for mermaid and defuddle skills)"
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        if ask_yes_no "Install Node.js via Homebrew now?"; then
            brew install node && ok "Node.js installed" || { fail "Homebrew install failed. Install manually: brew install node"; exit 1; }
        else
            info "Skipping Node.js install. Run: brew install node"
            echo "  mermaid and defuddle skills will not work without Node.js."
        fi
    elif [[ "$OS" == "Darwin" ]] && ! command -v brew &>/dev/null; then
        info "Homebrew not found. Install Node.js manually: https://nodejs.org"
        if ask_yes_no "Continue without Node.js?"; then
            warn "Skipping Node.js — mermaid and defuddle skills will not work"
        else
            exit 1
        fi
    elif [[ "$OS" == "Linux" ]]; then
        if ask_yes_no "Install Node.js via apt now? (requires sudo)"; then
            sudo apt-get update -q && sudo apt-get install -y nodejs npm && ok "Node.js installed" || { fail "apt install failed. Install manually: sudo apt install nodejs npm"; exit 1; }
        else
            info "Skipping Node.js install. Run: sudo apt install nodejs npm"
            warn "mermaid and defuddle skills will not work without Node.js"
        fi
    fi
else
    ok "Node.js $(node --version)"
fi

# npm
if ! command -v npm &>/dev/null; then
    fail "npm not found"
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        if ask_yes_no "Install npm via Homebrew now?"; then
            brew install npm && ok "npm installed" || { fail "Homebrew install failed"; exit 1; }
        else
            warn "Skipping npm — mermaid and defuddle skills will not work"
        fi
    elif [[ "$OS" == "Linux" ]]; then
        if ask_yes_no "Install npm via apt now? (requires sudo)"; then
            sudo apt-get install -y npm && ok "npm installed" || fail "apt install failed. Run: sudo apt install npm"
        else
            warn "Skipping npm — mermaid and defuddle skills will not work"
        fi
    fi
else
    ok "npm $(npm --version)"
fi

# git
if ! command -v git &>/dev/null; then
    case "$OS" in
        Darwin) fail "git not found. Install: xcode-select --install" ;;
        Linux)  fail "git not found. Install: sudo apt install git" ;;
    esac
    exit 1
fi
ok "git $(git --version | awk '{print $3}')"

# python3
if ! command -v python3 &>/dev/null; then
    warn "python3 not found — secret-vault skill will not work"
else
    ok "python3 $(python3 --version | awk '{print $2}')"
fi

echo ""

# ── npm SSL helper ──────────────────────────────
# Detect SSL cert errors and offer to configure npm cafile interactively
npm_install_with_ssl_fallback() {
    local pkg="$1"
    local tmplog
    tmplog=$(mktemp)

    if npm install -g "$pkg" >"$tmplog" 2>&1; then
        rm -f "$tmplog"
        return 0
    fi

    # Check if failure is SSL-related
    if grep -qiE "UNABLE_TO_GET_ISSUER_CERT|certificate|SSL|TLS" "$tmplog"; then
        warn "npm SSL/certificate error while installing $pkg"
        cat "$tmplog" | grep -i "npm error" | head -5
        rm -f "$tmplog"
        echo ""
        echo "  This usually means a corporate proxy is intercepting HTTPS traffic."
        echo "  Options:"
        echo "    1) Provide path to your corporate CA certificate file"
        echo "    2) Disable SSL verification (not recommended)"
        echo "    3) Skip and install manually later"
        echo ""
        read -r -p "$(echo -e "${CYAN}?${NC} Choose [1/2/3]: ")" ssl_choice
        case "$ssl_choice" in
            1)
                read -r -p "$(echo -e "${CYAN}?${NC} Path to CA cert file: ")" ca_path
                ca_path="${ca_path/#\~/$HOME}"
                if [[ -f "$ca_path" ]]; then
                    npm config set cafile "$ca_path"
                    ok "npm cafile set to: $ca_path"
                    echo "  Retrying $pkg install..."
                    if npm install -g "$pkg"; then
                        return 0
                    else
                        warn "$pkg install still failed after setting cafile"
                        return 1
                    fi
                else
                    warn "File not found: $ca_path"
                    return 1
                fi
                ;;
            2)
                if ask_yes_no "Set npm strict-ssl=false? (applies globally to your npm config)"; then
                    npm config set strict-ssl false
                    warn "npm SSL verification disabled"
                    echo "  Retrying $pkg install..."
                    if npm install -g "$pkg"; then
                        return 0
                    else
                        warn "$pkg install still failed"
                        return 1
                    fi
                fi
                return 1
                ;;
            *)
                warn "Skipping $pkg — install manually later: npm install -g $pkg"
                return 1
                ;;
        esac
    else
        warn "$pkg install failed"
        cat "$tmplog" | grep -i "npm error" | head -5
        rm -f "$tmplog"
        return 1
    fi
}

# ── Install npm dependencies ──────────────────
if command -v npm &>/dev/null; then
    echo "Installing dependencies..."

    if command -v mmdc &>/dev/null; then
        ok "mermaid-cli already installed ($(mmdc --version))"
    else
        echo "  Installing @mermaid-js/mermaid-cli (this may take a minute)..."
        if npm_install_with_ssl_fallback "@mermaid-js/mermaid-cli"; then
            ok "mermaid-cli installed"
        else
            warn "mermaid-cli not installed — run manually: npm install -g @mermaid-js/mermaid-cli"
        fi
    fi

    if command -v defuddle &>/dev/null; then
        ok "defuddle already installed"
    else
        echo "  Installing defuddle..."
        if npm_install_with_ssl_fallback "defuddle"; then
            ok "defuddle installed"
        else
            warn "defuddle not installed — run manually: npm install -g defuddle"
        fi
    fi

    # Linux ARM64: install system Chromium for mermaid
    if [[ "$OS" == "Linux" ]] && [[ "$(uname -m)" == "aarch64" ]]; then
        if ! command -v chromium-browser &>/dev/null && ! command -v chromium &>/dev/null; then
            warn "Linux ARM64 detected — mermaid needs system Chromium"
            if ask_yes_no "Install chromium-browser via apt now? (requires sudo)"; then
                sudo apt-get install -y chromium-browser && ok "chromium-browser installed" || warn "Install failed. Run: sudo apt install chromium-browser"
            else
                info "Run manually: sudo apt install chromium-browser"
            fi
        else
            ok "System Chromium available (ARM64)"
        fi
    fi

    echo ""
fi

# Python cryptography for secret-vault
if command -v python3 &>/dev/null; then
    if python3 -c "import cryptography" 2>/dev/null; then
        ok "cryptography package installed"
    else
        echo "  Installing cryptography for secret-vault..."
        if pip3 install cryptography 2>&1 | tail -3; then
            ok "cryptography installed"
        else
            warn "cryptography install failed — try: pip3 install cryptography"
        fi
    fi
fi

echo ""

# ── Symlink skills into Claude Code ───────────
echo "Linking skills into Claude Code (~/.claude/skills/)..."
mkdir -p "$CLAUDE_SKILLS"

# Auto-discover skills: any directory containing a SKILL.md
for skill_md in "$REPO_DIR"/*/SKILL.md; do
    skill_dir="$(dirname "$skill_md")"
    skill="$(basename "$skill_dir")"
    rm -rf "$CLAUDE_SKILLS/$skill" 2>/dev/null
    ln -sf "$skill_dir" "$CLAUDE_SKILLS/$skill"
    ok "$skill"
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

if command -v mmdc &>/dev/null && mmdc -i "$TESTFILE" -o "$OUTFILE" -t dark &>/dev/null; then
    ok "Mermaid rendering works"
else
    warn "Mermaid rendering failed — try: npx puppeteer browsers install chrome"
fi
rm -f "$TESTFILE" "$OUTFILE"

# List final state
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installed Skills"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for d in "$CLAUDE_SKILLS"/*/; do
    [ -d "$d" ] || continue
    skill=$(basename "$d")
    target=$(readlink "$d" 2>/dev/null || echo "local")
    echo -e "  ${GREEN}✓${NC} /$(printf '%-20s' "$skill") → $(echo "$target" | sed "s|$HOME|~|")"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}Done!${NC} Restart Claude Code to pick up skills."
echo "  Type / to see available skills."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
