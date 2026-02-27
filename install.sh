#!/usr/bin/env bash
# AI Memory Kit — One-Line Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/leizerowicz/ai-memory-kit/main/install.sh | bash
#
# Downloads the kit, runs setup for Claude Code, then cleans up.

set -euo pipefail

REPO="leizerowicz/ai-memory-kit"
BRANCH="main"
TMP_DIR="$(mktemp -d)"
KIT_DIR="$TMP_DIR/ai-memory-kit-$BRANCH"

echo ""
echo "AI Memory Kit — Installing..."
echo ""

# Download
curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" \
    | tar -xz -C "$TMP_DIR"

# Run setup
bash "$KIT_DIR/setup.sh" --tool claude-code

# Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "Installation complete."
echo "Run /init-memory in any Claude Code session to initialize a repo."
echo ""
