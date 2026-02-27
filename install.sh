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

# Keep the kit locally so backup/setup.sh and future updates are available
KIT_DEST="$HOME/.claude/memory-kit"
rm -rf "$KIT_DEST"
cp -r "$KIT_DIR" "$KIT_DEST"

# Cleanup temp
rm -rf "$TMP_DIR"

echo ""
echo "Installation complete."
echo "Kit installed to: $KIT_DEST"
echo ""
echo "Next: run /init-memory in any Claude Code session to initialize a repo."
echo "To set up backup, tell Claude: 'Set up backup using <your-private-repo-url>'"
echo ""
