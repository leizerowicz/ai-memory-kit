#!/usr/bin/env bash
# AI Memory Kit — Backup Push Hook
# Runs at session end. Syncs ~/.claude/ memory files to backup repo and pushes.
# Silently no-ops if backup isn't configured or nothing changed.

set -euo pipefail

MEMORY_DIR="$HOME/.claude"
BACKUP_DIR_FILE="$MEMORY_DIR/.backup-dir"

[ -f "$BACKUP_DIR_FILE" ] || exit 0
BACKUP_DIR="$(cat "$BACKUP_DIR_FILE")"
[ -d "$BACKUP_DIR/.git" ] || exit 0
command -v git &>/dev/null || exit 0

# Sync: ~/.claude/ -> backup repo
rsync -a \
    "$MEMORY_DIR/global-state.md" \
    "$MEMORY_DIR/state.md" \
    "$BACKUP_DIR/" 2>/dev/null || true

if [ -d "$MEMORY_DIR/memory" ]; then
    rsync -a "$MEMORY_DIR/memory/" "$BACKUP_DIR/memory/" 2>/dev/null || true
fi

# Commit and push if anything changed
cd "$BACKUP_DIR" || { echo "ERROR: cannot cd to backup dir $BACKUP_DIR"; exit 1; }
git add -A
if git diff --cached --quiet; then
    exit 0  # Nothing changed — skip silently
fi

git commit -m "auto: $(date '+%Y-%m-%d %H:%M')" --quiet

# Push
if git push origin "${BRANCH:-main}" --quiet 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M')" > "$HOME/.claude/.backup-last-push"
else
    echo "$(date '+%Y-%m-%d %H:%M') — git push failed. Check remote auth and network." > "$HOME/.claude/.backup-last-error"
    echo "Warning: Backup push failed. Details: $HOME/.claude/.backup-last-error"
    exit 1
fi
