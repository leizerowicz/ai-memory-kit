#!/usr/bin/env bash
# AI Memory Kit — Installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/leizerowicz/ai-memory-kit/main/install.sh | bash
#   AIMK_VERSION=v1.0.0 bash install.sh   # Install specific version

set -euo pipefail

REPO="leizerowicz/ai-memory-kit"
VERSION="${AIMK_VERSION:-main}"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo ""
echo "AI Memory Kit — Installing${VERSION:+ (${VERSION})}..."
echo ""

# Download
if [ "$VERSION" = "main" ]; then
    DOWNLOAD_URL="https://github.com/$REPO/archive/refs/heads/main.tar.gz"
    ARCHIVE_NAME="ai-memory-kit-main"
else
    DOWNLOAD_URL="https://github.com/$REPO/archive/refs/tags/${VERSION}.tar.gz"
    ARCHIVE_NAME="ai-memory-kit-${VERSION#v}"
fi

curl -fsSL "$DOWNLOAD_URL" | tar -xz -C "$TMP_DIR"
KIT_DIR="$TMP_DIR/$ARCHIVE_NAME"

# Verify the kit downloaded correctly
if [ ! -f "$KIT_DIR/setup.sh" ]; then
    echo "Error: download failed or unexpected archive structure"
    exit 1
fi

# Run setup
bash "$KIT_DIR/setup.sh" --tool claude-code

# Keep the kit locally so doctor.sh and future updates are available
KIT_DEST="$HOME/.claude/memory-kit"
rm -rf "$KIT_DEST"
cp -r "$KIT_DIR" "$KIT_DEST"

echo ""
echo "Installation complete."
[ "$VERSION" != "main" ] && echo "Version: $VERSION"
echo "Kit installed to: $KIT_DEST"
echo ""
echo "Next: run /init-memory in any Claude Code session to initialize a repo."
echo "To set up backup: tell Claude 'Set up backup using <your-private-repo-url>'"
echo ""
